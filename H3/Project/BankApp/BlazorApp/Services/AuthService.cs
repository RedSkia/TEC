using BankApp.Data;
using BankApp.Data.Entities.Auth;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Components.Authorization;
using System.Security.Claims;
using Microsoft.Extensions.Options;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Services;

public interface IAuthService
{
    Task<string?> Login(string username, string password);
    Task<IEnumerable<string>?> Register(string email, string password, RoleType role, string username, string fullName, string street, string city, string zipCode);
    Task<IdentityResult> ChangePasswordUser(string oldPassword, string newPassword);
    Task<IdentityResult> ChangePasswordStaff(string staffUserId, string newPassword);
    Task<IdentityResult> ForcePasswordReset(string username, string newPassword);
    Task<bool> UpdateUserProfile(ApplicationUser user);
    Task<bool> CloseAccount(string userId);
    Task<ApplicationUser?> GetCurrentApplicationUser();
    Task<ApplicationRole?> GetCurrentApplicationRole();
    Task Logout();
}

public class AuthService(
    UserManager<ApplicationUser> userManager,
    ITokenService tokenService,
    AuthenticationStateProvider authStateProvider,
    IDbContextFactory<BankAppDbContext> dbFactory,
    IHttpContextAccessor httpContextAccessor,
    IOptions<IdentityOptions> identityOptions) : IAuthService
{
    private readonly PasswordOptions _pwdRules = identityOptions.Value.Password;

    public async Task<string?> Login(string username, string password)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var user = await db.Users.FirstOrDefaultAsync(u => u.UserName == username);
        if (user == null) return null;

        var isValid = await userManager.CheckPasswordAsync(user, password);
        await LogActivity(user.Id, isValid ? LoginStatus.Success : LoginStatus.Failed);

        if (!isValid) return null;

        var roles = await userManager.GetRolesAsync(user);
        var token = tokenService.CreateToken(user, roles);

        if (authStateProvider is JwtAuthStateProvider jwtProvider)
            await jwtProvider.NotifyUserLogin(token);

        return token;
    }

    public async Task<IEnumerable<string>?> Register(string email, string password, RoleType role, string username, string fullName, string street, string city, string zipCode)
    {
        var pwdErrors = ValidatePassword(password);
        if (pwdErrors.Any()) return pwdErrors;

        var user = new ApplicationUser
        {
            UserName = username,
            Email = email,
            FullName = fullName,
            EmailConfirmed = true,
            Address = new Address { Street = street, City = city, ZipCode = zipCode }
        };

        var result = await userManager.CreateAsync(user, password);
        if (!result.Succeeded) return result.Errors.Select(e => e.Description);

        await userManager.AddToRoleAsync(user, role.ToString());
        return null;
    }

    public async Task<bool> UpdateUserProfile(ApplicationUser updatedUser)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var user = await db.Users.Include(u => u.Address).FirstOrDefaultAsync(u => u.Id == updatedUser.Id);
        if (user == null) return false;

        user.FullName = updatedUser.FullName;
        if (user.Address != null && updatedUser.Address != null)
        {
            user.Address.Street = updatedUser.Address.Street;
            user.Address.City = updatedUser.Address.City;
            user.Address.ZipCode = updatedUser.Address.ZipCode;
        }

        return await db.SaveChangesAsync() > 0;
    }

    public async Task<bool> CloseAccount(string userId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var user = await db.Users.Include(u => u.BankAccounts).FirstOrDefaultAsync(u => u.Id == userId);

        // Security check: Don't delete if they still have money
        if (user == null || user.BankAccounts.Any(a => a.Balance > 0)) return false;

        db.Users.Remove(user);
        return await db.SaveChangesAsync() > 0;
    }

    public async Task<IdentityResult> ChangePasswordUser(string oldPassword, string newPassword)
    {
        var user = await GetCurrentApplicationUser();
        if (user == null) return IdentityErrorResult("User session not found.");

        if (!await userManager.IsInRoleAsync(user, RoleType.Customer.ToString()))
            return IdentityErrorResult("Staff must contact an Admin for security updates.");

        var pwdErrors = ValidatePassword(newPassword);
        if (pwdErrors.Any()) return IdentityResult.Failed(pwdErrors.Select(e => new IdentityError { Description = e }).ToArray());

        return await userManager.ChangePasswordAsync(user, oldPassword, newPassword);
    }

    public async Task<IdentityResult> ForcePasswordReset(string username, string newPassword)
    {
        var user = await userManager.FindByNameAsync(username);
        if (user == null) return IdentityErrorResult("Account not found.");

        var pwdErrors = ValidatePassword(newPassword);
        if (pwdErrors.Any()) return IdentityResult.Failed(pwdErrors.Select(e => new IdentityError { Description = e }).ToArray());

        await userManager.RemovePasswordAsync(user);
        return await userManager.AddPasswordAsync(user, newPassword);
    }

    public async Task<IdentityResult> ChangePasswordStaff(string staffUserId, string newPassword)
    {
        var admin = await GetCurrentApplicationUser();
        if (admin == null || !await userManager.IsInRoleAsync(admin, RoleType.Admin.ToString()))
            return IdentityErrorResult("Unauthorized: Admin elevation required.");

        var targetUser = await userManager.FindByIdAsync(staffUserId);
        if (targetUser == null) return IdentityErrorResult("Staff record not found.");

        var token = await userManager.GeneratePasswordResetTokenAsync(targetUser);
        return await userManager.ResetPasswordAsync(targetUser, token, newPassword);
    }

    public async Task Logout()
    {
        if (authStateProvider is JwtAuthStateProvider jwtProvider) await jwtProvider.NotifyUserLogout();
    }

    public async Task<ApplicationUser?> GetCurrentApplicationUser()
    {
        var authState = await authStateProvider.GetAuthenticationStateAsync();
        var userId = authState.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return null;

        using var db = await dbFactory.CreateDbContextAsync();
        return await db.Users
            .Include(u => u.Address)
            .Include(u => u.BankAccounts)
                .ThenInclude(a => a.Transactions)
            .Include(u => u.LoginActivities)
            .FirstOrDefaultAsync(u => u.Id == userId);
    }

    public async Task<ApplicationRole?> GetCurrentApplicationRole()
    {
        var authState = await authStateProvider.GetAuthenticationStateAsync();
        var roleName = authState.User.FindFirst(ClaimTypes.Role)?.Value;
        if (roleName == null) return null;

        using var db = await dbFactory.CreateDbContextAsync();
        return await db.Roles.FirstOrDefaultAsync(r => r.Name == roleName);
    }

    private List<string> ValidatePassword(string password)
    {
        var e = new List<string>();
        if (string.IsNullOrWhiteSpace(password)) return ["Password is required."];
        if (password.Length < _pwdRules.RequiredLength) e.Add($"Length must be {_pwdRules.RequiredLength}+.");
        if (_pwdRules.RequireDigit && !password.Any(char.IsDigit)) e.Add("Include a number.");
        if (_pwdRules.RequireLowercase && !password.Any(char.IsLower)) e.Add("Include lowercase.");
        if (_pwdRules.RequireUppercase && !password.Any(char.IsUpper)) e.Add("Include uppercase.");
        if (_pwdRules.RequireNonAlphanumeric && password.All(char.IsLetterOrDigit)) e.Add("Include a special char.");
        return e;
    }

    private async Task LogActivity(string userId, LoginStatus status)
    {
        var ctx = httpContextAccessor.HttpContext;
        var activity = new LoginActivity
        {
            UserId = userId,
            Status = status,
            LoginTime = DateTime.UtcNow,
            IpAddress = ctx?.Connection?.RemoteIpAddress?.ToString() ?? "Unknown",
            UserAgent = ctx?.Request.Headers.UserAgent.ToString() ?? "Unknown"
        };
        using var db = await dbFactory.CreateDbContextAsync();
        db.LoginActivities.Add(activity);
        await db.SaveChangesAsync();
    }

    private IdentityResult IdentityErrorResult(string message)
        => IdentityResult.Failed(new IdentityError { Description = message });
}
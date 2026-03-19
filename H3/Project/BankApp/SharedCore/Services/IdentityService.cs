using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.JSInterop;
using SharedCore.Data;
using SharedCore.Entities.Auth;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace SharedCore.Services;

public class IdentityService : AuthenticationStateProvider
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IDbContextFactory<BankAppDbContext> _dbFactory;
    private readonly IConfiguration _config;
    private readonly IJSRuntime _jsRuntime;

    private ClaimsPrincipal _currentUser = new ClaimsPrincipal(new ClaimsIdentity());

    public IdentityService(
        UserManager<ApplicationUser> userManager,
        IDbContextFactory<BankAppDbContext> dbFactory,
        IConfiguration config,
        IJSRuntime jsRuntime)
    {
        _userManager = userManager;
        _dbFactory = dbFactory;
        _config = config;
        _jsRuntime = jsRuntime;
    }

    // -----------------------------------------------------
    // AUTH STATE
    // -----------------------------------------------------

    public override async Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        // Optimization: Don't read from JS if we already have the state in memory
        if (_currentUser.Identity?.IsAuthenticated == true)
        {
            return new AuthenticationState(_currentUser);
        }

        try
        {
            var token = await _jsRuntime.InvokeAsync<string>("localStorage.getItem", "authToken");

            if (!string.IsNullOrEmpty(token))
            {
                var identity = new ClaimsIdentity(ParseClaimsFromJwt(token), "jwt");
                _currentUser = new ClaimsPrincipal(identity);
            }
        }
        catch
        {
            // Prerendering failsafe
        }

        return new AuthenticationState(_currentUser);
    }

    public bool IsUserAuthenticated()
    {
        return _currentUser.Identity?.IsAuthenticated ?? false;
    }

    // -----------------------------------------------------
    // LOGIN
    // -----------------------------------------------------
    public async Task<string?> Login(string username, string password)
    {
        var user = await _userManager.FindByNameAsync(username);
        using var db = await _dbFactory.CreateDbContextAsync();

        if (user == null || !await _userManager.CheckPasswordAsync(user, password))
        {
            db.LoginActivities.Add(new LoginActivity { UserId = user?.Id ?? "UNKNOWN", Status = LoginStatus.InvalidPassword, LoginTime = DateTime.UtcNow });
            await db.SaveChangesAsync();
            return null;
        }

        var roles = await _userManager.GetRolesAsync(user);
        var token = GenerateJwtToken(user, roles);

        var identity = new ClaimsIdentity(ParseClaimsFromJwt(token), "jwt");
        _currentUser = new ClaimsPrincipal(identity);

        await _jsRuntime.InvokeVoidAsync("localStorage.setItem", "authToken", token);

        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(_currentUser)));

        db.LoginActivities.Add(new LoginActivity { UserId = user.Id, Status = LoginStatus.Success, LoginTime = DateTime.UtcNow });
        await db.SaveChangesAsync();

        return token;
    }

    // -----------------------------------------------------
    // LOGOUT
    // -----------------------------------------------------
    public async Task Logout()
    {
        // 1. Wipe the internal principal immediately
        _currentUser = new ClaimsPrincipal(new ClaimsIdentity());

        // 2. Remove token from storage
        try
        {
            await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "authToken");
        }
        catch { }

        // 3. Notify the UI instantly with the empty state
        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(_currentUser)));
    }


    // -----------------------------------------------------
    // PASSWORD MANAGEMENT
    // -----------------------------------------------------

    public async Task<IdentityResult> ResetPassword(string username, string newPassword)
    {
        var user = await _userManager.FindByNameAsync(username);

        if (user == null)
        {
            return IdentityResult.Failed(new IdentityError
            {
                Code = "UserNotFound",
                Description = "IDENTITY_NOT_FOUND: The specified subject does not exist."
            });
        }

        var token = await _userManager.GeneratePasswordResetTokenAsync(user);
        var result = await _userManager.ResetPasswordAsync(user, token, newPassword);

        if (result.Succeeded)
        {
            using var db = await _dbFactory.CreateDbContextAsync();
            db.LoginActivities.Add(new LoginActivity
            {
                UserId = user.Id,
                Status = LoginStatus.Success,
                LoginTime = DateTime.UtcNow
            });
            await db.SaveChangesAsync();
        }

        return result;
    }

    // -----------------------------------------------------
    // JWT CREATION
    // -----------------------------------------------------

    private string GenerateJwtToken(ApplicationUser user, IList<string> roles)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["JWT:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id),
            new Claim(ClaimTypes.Name, user.UserName!)
        };

        foreach (var role in roles)
            claims.Add(new Claim(ClaimTypes.Role, role));

        var token = new JwtSecurityToken(
            issuer: _config["JWT:Issuer"],
            audience: _config["JWT:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    // -----------------------------------------------------
    // JWT PARSING
    // -----------------------------------------------------

    private IEnumerable<Claim> ParseClaimsFromJwt(string jwt)
    {
        var handler = new JwtSecurityTokenHandler();
        var token = handler.ReadJwtToken(jwt);
        return token.Claims;
    }

    // -----------------------------------------------------
    // USER RETRIEVAL & MANAGEMENT
    // -----------------------------------------------------

    public async Task<ApplicationUser?> GetCurrentUserAsync()
    {
        var authState = await GetAuthenticationStateAsync();
        var userPrincipal = authState.User;

        var userId = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return null;

        using var db = await _dbFactory.CreateDbContextAsync();

        return await db.Users
            .Include(u => u.Address)
            .Include(u => u.LoginActivities)
            .Include(u => u.BankAccount)
                .ThenInclude(b => b!.CurrencyType)
            .Include(u => u.BankAccount)
                .ThenInclude(b => b!.Transactions)
                    .ThenInclude(t => t.CurrencyType)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId);
    }

    public async Task<List<ApplicationUser>> GetAllUsersExceptAsync(string excludeUserId)
    {
        using var db = await _dbFactory.CreateDbContextAsync();
        return await db.Users
            .Where(u => u.Id != excludeUserId)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<bool> UpdateUserProfileAsync(string userId, ApplicationUser updatedData)
    {
        using var db = await _dbFactory.CreateDbContextAsync();
        var user = await db.Users.Include(u => u.Address).FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return false;

        user.FullName = updatedData.FullName;

        if (user.Address == null)
        {
            user.Address = updatedData.Address;
        }
        else if (updatedData.Address != null)
        {
            user.Address.Street = updatedData.Address.Street;
            user.Address.City = updatedData.Address.City;
            user.Address.ZipCode = updatedData.Address.ZipCode;
        }

        var result = await db.SaveChangesAsync();
        return result > 0;
    }

    public async Task<bool> DeleteAccountAsync(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null) return false;

        var result = await _userManager.DeleteAsync(user);

        if (result.Succeeded)
        {
            await Logout();
            return true;
        }
        return false;
    }

    // -----------------------------------------------------
    // USER RETRIEVAL
    // -----------------------------------------------------

    public async Task<ApplicationUser?> GetCurrentApplicationUserAsync()
    {
        var userId = _currentUser.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return null;

        using var db = await _dbFactory.CreateDbContextAsync();

        return await db.Users
            .Include(u => u.Address)
            .Include(u => u.BankAccount)
            .ThenInclude(b => b!.CurrencyType)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId);
    }

    public async Task<ApplicationRole?> GetCurrentApplicationRoleAsync()
    {
        var userId = _currentUser.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return null;

        using var db = await _dbFactory.CreateDbContextAsync();

        var userRole = await db.UserRoles.AsNoTracking().FirstOrDefaultAsync(ur => ur.UserId == userId);
        if (userRole == null) return null;

        return await db.Roles.AsNoTracking().FirstOrDefaultAsync(r => r.Id == userRole.RoleId);
    }

    // -----------------------------------------------------
    // REGISTER
    // -----------------------------------------------------

    public async Task<IEnumerable<string>?> Register(ApplicationUser user, string password, RoleType role = RoleType.Customer)
    {
        var result = await _userManager.CreateAsync(user, password);

        if (!result.Succeeded)
            return result.Errors.Select(e => e.Description);

        await _userManager.AddToRoleAsync(user, role.ToString());
        return null;
    }

    // -----------------------------------------------------
    // ROLE CHECK
    // -----------------------------------------------------

    public bool IsUserInRole(RoleType role)
    {
        return _currentUser.IsInRole(role.ToString()) || _currentUser.IsInRole(RoleType.Admin.ToString());
    }
}
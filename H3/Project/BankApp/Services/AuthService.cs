using BankApp.Data;
using BankApp.Data.Entities.Auth;
using Microsoft.AspNetCore.Identity;
using System.Security.Claims;

namespace BankApp.Services;

public interface IAuthService
{
    Task<string?> Login(string username, string password);
    Task<IEnumerable<string>?> Register(string email, string password, string name, RoleType role, string username);
    Task<ApplicationUser?> GetCurrentUser();
}

public class AuthService(
    UserManager<ApplicationUser> userManager,
    ITokenService tokenService,
    AuthenticationStateProvider authStateProvider,
    BankAppDbContext dbContext, // Inject DB Context
    IHttpContextAccessor httpContextAccessor) : IAuthService // To get IP Address
{
    public async Task<string?> Login(string username, string password)
    {
        var user = await userManager.FindByNameAsync(username);
        var ip = httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString() ?? "Unknown";
        var userAgent = httpContextAccessor.HttpContext?.Request.Headers["User-Agent"].ToString();

        // 1. Handle user not found
        if (user == null) return null;

        // 2. Check password
        var isPasswordValid = await userManager.CheckPasswordAsync(user, password);

        // 3. LOG THE ACTIVITY
        var activity = new LoginActivity
        {
            UserId = user.Id,
            IpAddress = ip,
            UserAgent = userAgent,
            LoginTime = DateTime.UtcNow,
            Status = isPasswordValid ? LoginStatus.Success : LoginStatus.Failed
        };

        dbContext.LoginActivities.Add(activity);
        await dbContext.SaveChangesAsync();

        if (!isPasswordValid) return null;

        // 4. Generate Token on success
        var roles = await userManager.GetRolesAsync(user);
        return tokenService.CreateToken(user, roles);
    }

    public async Task<ApplicationUser?> GetCurrentUser()
    {
        var authState = await authStateProvider.GetAuthenticationStateAsync();
        var userPrincipal = authState.User;

        // Check if authenticated
        if (userPrincipal.Identity?.IsAuthenticated != true)
            return null;

        // Identity stores the User ID in NameIdentifier claim
        var userId = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(userId))
            return null;

        // Fetch user and include any related data if necessary
        return await userManager.FindByIdAsync(userId);
    }

    public async Task<IEnumerable<string>?> Register(string email, string password, string name, RoleType role, string username)
    {
        var user = new ApplicationUser
        {
            UserName = username,
            Email = email,
            FullName = name,
            EmailConfirmed = true,
        };

        // Identity handles all Program.cs validation rules here automatically
        var result = await userManager.CreateAsync(user, password);

        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(user, role.ToString());
            return null; // Null means success
        }

        // Return the specific reasons why it failed
        return result.Errors.Select(e => e.Description);
    }
}
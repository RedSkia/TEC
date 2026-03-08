using BankApp.Data;
using BankApp.Data.Entities.Auth;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace BankApp.Services;

public interface IAuthService
{
    Task<string?> Login(string username, string password);
    Task<IEnumerable<string>?> Register(string email, string password, string name, RoleType role, string username);
    Task<ApplicationUser?> GetCurrentApplicationUser();
    Task<ApplicationRole?> GetCurrentApplicationRole();
    Task Logout();
}

public class AuthService(
    IServiceProvider serviceProvider, // Needed to create manual scopes for Identity
    ITokenService tokenService,
    AuthenticationStateProvider authStateProvider,
    IDbContextFactory<BankAppDbContext> dbFactory,
    IHttpContextAccessor httpContextAccessor) : IAuthService
{
    public async Task<string?> Login(string username, string password)
    {
        using var scope = serviceProvider.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        var user = await userManager.FindByNameAsync(username);
        if (user == null) return null;

        var isPasswordValid = await userManager.CheckPasswordAsync(user, password);

        using (var dbContext = await dbFactory.CreateDbContextAsync())
        {
            var ip = httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString() ?? "Unknown";
            var userAgent = httpContextAccessor.HttpContext?.Request.Headers["User-Agent"].ToString();

            dbContext.LoginActivities.Add(new LoginActivity
            {
                UserId = user.Id,
                IpAddress = ip,
                UserAgent = userAgent,
                LoginTime = DateTime.UtcNow,
                Status = isPasswordValid ? LoginStatus.Success : LoginStatus.Failed
            });
            await dbContext.SaveChangesAsync();
        }

        if (!isPasswordValid) return null;

        var roles = await userManager.GetRolesAsync(user);
        var token = tokenService.CreateToken(user, roles);

        if (authStateProvider is JwtAuthStateProvider jwtProvider)
        {
            await jwtProvider.NotifyUserLogin(token);
        }

        return token;
    }

    public async Task Logout()
    {
        if (authStateProvider is JwtAuthStateProvider jwtProvider)
        {
            await jwtProvider.NotifyUserLogout();
        }
    }

    public async Task<ApplicationUser?> GetCurrentApplicationUser()
    {
        var authState = await authStateProvider.GetAuthenticationStateAsync();
        var userId = authState.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return null;

        using var scope = serviceProvider.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        return await userManager.FindByIdAsync(userId);
    }

    public async Task<ApplicationRole?> GetCurrentApplicationRole()
    {
        var authState = await authStateProvider.GetAuthenticationStateAsync();
        var roleName = authState.User.FindFirst(ClaimTypes.Role)?.Value;
        if (string.IsNullOrEmpty(roleName)) return null;

        // FIX: Create a scope so RoleManager gets a fresh, non-colliding DbContext
        using var scope = serviceProvider.CreateScope();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<ApplicationRole>>();

        return await roleManager.FindByNameAsync(roleName);
    }

    public async Task<IEnumerable<string>?> Register(string email, string password, string name, RoleType role, string username)
    {
        using var scope = serviceProvider.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        var user = new ApplicationUser { UserName = username, Email = email, FullName = name, EmailConfirmed = true };
        var result = await userManager.CreateAsync(user, password);

        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(user, role.ToString());
            return null;
        }
        return result.Errors.Select(e => e.Description);
    }
}
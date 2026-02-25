using BankApp.Data.Entities.Auth;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace BankApp.Services;

// 1. Kontrakten (Hvad skal vi kunne?)
public interface ITokenService
{
    string CreateToken(ApplicationUser user, IList<string> roles);
}

// 2. JWT Motoren (ID-kort maskinen)
public class TokenService(IConfiguration config) : ITokenService
{
    public string CreateToken(ApplicationUser user, IList<string> roles)
    {
        var claims = new List<Claim> {
            new Claim(JwtRegisteredClaimNames.NameId, user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email!)
        };
        foreach (var role in roles) claims.Add(new Claim(ClaimTypes.Role, role));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha512Signature);

        var token = new JwtSecurityToken(
            issuer: config["Jwt:Issuer"],
            audience: config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.Now.AddDays(1),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
public class AuthService(UserManager<ApplicationUser> userManager, ITokenService tokenService)
{
    public async Task<string?> Login(string email, string password)
    {
        var user = await userManager.FindByEmailAsync(email);
        if (user == null || !await userManager.CheckPasswordAsync(user, password)) return null;

        var roles = await userManager.GetRolesAsync(user);
        return tokenService.CreateToken(user, roles);
    }

    public async Task<bool> Register(string email, string password, string name, RoleType role)
    {
        var user = new ApplicationUser { UserName = email, Email = email, FullName = name, EmailConfirmed = true };
        var result = await userManager.CreateAsync(user, password);

        if (result.Succeeded)
        {
            // Vi bruger .ToString() for at matche databasens RoleName
            await userManager.AddToRoleAsync(user, role.ToString());
            return true;
        }
        return false;
    }
}
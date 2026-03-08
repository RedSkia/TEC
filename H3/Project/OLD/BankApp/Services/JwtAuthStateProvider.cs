using Microsoft.AspNetCore.Components.Authorization;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace BankApp.Services;

public class JwtAuthStateProvider(TokenStorageService storage) : AuthenticationStateProvider
{
    private readonly ClaimsPrincipal _anonymous = new(new ClaimsIdentity());

    public override async Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        try
        {
            var token = await storage.GetToken();

            if (string.IsNullOrWhiteSpace(token))
                return new AuthenticationState(_anonymous);

            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);

            if (jwtToken.ValidTo < DateTime.UtcNow)
            {
                await storage.RemoveToken();
                return new AuthenticationState(_anonymous);
            }

            var identity = new ClaimsIdentity(jwtToken.Claims, "jwt", ClaimTypes.Name, ClaimTypes.Role);
            return new AuthenticationState(new ClaimsPrincipal(identity));
        }
        catch
        {
            return new AuthenticationState(_anonymous);
        }
    }

    public async Task NotifyUserLogin(string token)
    {
        await storage.SetToken(token);
        var authState = await GetAuthenticationStateAsync();
        NotifyAuthenticationStateChanged(Task.FromResult(authState));
    }

    public async Task NotifyUserLogout()
    {
        await storage.RemoveToken();
        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(_anonymous)));
    }
}
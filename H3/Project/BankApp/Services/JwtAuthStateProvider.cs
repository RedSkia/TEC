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
            // Add this check to prevent 401s during the server-side bootup
            // If the circuit isn't connected, we can't talk to the browser storage yet.
            var token = await storage.GetToken();

            if (string.IsNullOrWhiteSpace(token))
                return new AuthenticationState(_anonymous);

            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);

            if (jwtToken.ValidTo < DateTime.UtcNow)
            {
                return new AuthenticationState(_anonymous);
            }

            var identity = new ClaimsIdentity(jwtToken.Claims, "jwt", ClaimTypes.Name, ClaimTypes.Role);
            return new AuthenticationState(new ClaimsPrincipal(identity));
        }
        catch
        {
            // IMPORTANT: If we catch an error (like JS Interop not available), 
            // we return Anonymous so the app can at least LOAD, 
            // then it will re-check once Interactive connection is live.
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
using Microsoft.JSInterop;

namespace BankApp.Services;

public class TokenStorageService(IJSRuntime js)
{
    public async Task SetToken(string token)
        => await js.InvokeVoidAsync("localStorage.setItem", "authToken", token);

    public async Task<string?> GetToken()
    {
        try
        {
            return await js.InvokeAsync<string?>("localStorage.getItem", "authToken");
        }
        catch
        {
            return null; // Catch errors during Prerendering
        }
    }

    public async Task RemoveToken()
        => await js.InvokeVoidAsync("localStorage.removeItem", "authToken");
}
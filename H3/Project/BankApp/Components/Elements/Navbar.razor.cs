using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;

namespace BankApp.Components.Elements;

public partial class Navbar
{
    [Parameter]
    public string Title { get; set; } = "";
    [Parameter] public string Subtitle { get; set; } = "";

    private async Task HandleLogout()
    {
        // 1. Since you use JWT, we need to clear the token from the browser
        // Assuming you store it in LocalStorage via JS Interop
        await JS.InvokeVoidAsync("localStorage.removeItem", "authToken");

        // 2. Redirect to Login or Home
        Nav.NavigateTo("/login", forceLoad: true);
    }
}

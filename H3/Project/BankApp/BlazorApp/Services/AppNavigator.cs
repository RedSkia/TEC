using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using BankApp.Data.Entities.Auth;
using BankApp.Data.Constants;
using System.Reflection;

namespace BankApp.Services;

public class AppNavigator(NavigationManager nav, AuthenticationStateProvider auth)
{
    public async Task NavigateTo(string route)
    {
        // 1. Find if this route string exists in AppRoutes and has a Role Attribute
        var field = typeof(AppRoutes).GetFields(BindingFlags.Public | BindingFlags.Static)
            .FirstOrDefault(f => f.GetValue(null)?.ToString() == route);

        var requiredAttr = field?.GetCustomAttribute<RouteRoleAttribute>();

        // 2. If no attribute is required, go freely
        if (requiredAttr == null)
        {
            nav.NavigateTo(route);
            return;
        }

        // 3. Check Authentication State
        var state = await auth.GetAuthenticationStateAsync();
        var user = state.User;

        if (user.Identity?.IsAuthenticated != true)
        {
            nav.NavigateTo(AppRoutes.Login);
            return;
        }

        // 4. Check Authorization (Admin bypasses all)
        if (user.IsInRole(RoleType.Admin.ToString()) || user.IsInRole(requiredAttr.Role.ToString()))
        {
            nav.NavigateTo(route);
        }
        else
        {
            
            // Redirect to 403 Access Restricted
            nav.NavigateTo("/error/403");
        }
    }
}
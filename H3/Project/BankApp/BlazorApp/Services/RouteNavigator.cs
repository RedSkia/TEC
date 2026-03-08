using Microsoft.AspNetCore.Components;
using BankApp.Services;
using System.Reflection;
using BankApp.Data.Constants;
using BankApp.Data.Entities.Auth;

namespace BankApp.Services;

public interface IRouteNavigator
{
    Task NavigateTo(string route);
}

public class RouteNavigator(NavigationManager nav, IAuthService auth) : IRouteNavigator
{
    public async Task NavigateTo(string route)
    {
        // 1. Find the field in AppRoutes
        var field = typeof(AppRoutes).GetFields()
            .FirstOrDefault(f => f.GetValue(null)?.ToString() == route);

        var attr = field?.GetCustomAttribute<RouteRoleAttribute>();

        // 2. Public page check
        if (attr == null)
        {
            nav.NavigateTo(route);
            return;
        }

        // 3. Get User Role String (from Database)
        var userRole = await auth.GetCurrentApplicationRole(); // Returns ApplicationRole entity

        // 4. Convert String to Enum for comparison
        if (Enum.TryParse<RoleType>(userRole?.Name, out var userRoleEnum))
        {
            // 5. Authorization Check
            if (userRoleEnum == RoleType.Admin || userRoleEnum == attr.Role)
            {
                nav.NavigateTo(route);
            }
            else
            {
                nav.NavigateTo(AppRoutes.Index);
            }
        }
        else
        {
            nav.NavigateTo(AppRoutes.Login);
        }
    }
}
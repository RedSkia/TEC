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
    // Static cache so we only perform Reflection once for the entire app lifetime
    private static readonly Dictionary<string, RoleType?> RouteCache = typeof(AppRoutes)
        .GetFields(BindingFlags.Public | BindingFlags.Static)
        .ToDictionary(
            f => f.GetValue(null)?.ToString() ?? "",
            f => f.GetCustomAttribute<RouteRoleAttribute>()?.Role
        );

    public async Task NavigateTo(string route)
    {
        // 1. Fast lookup
        if (!RouteCache.TryGetValue(route, out var requiredRole))
        {
            nav.NavigateTo(route); // Public page
            return;
        }

        var userRole = await auth.GetCurrentApplicationRole();

        if (userRole != null && Enum.TryParse<RoleType>(userRole.Name, out var userRoleEnum))
        {
            // Admin bypass or matching role
            if (userRoleEnum == RoleType.Admin || userRoleEnum == requiredRole)
            {
                nav.NavigateTo(route);
                return;
            }
            nav.NavigateTo(AppRoutes.Index);
        }
        else
        {
            nav.NavigateTo(AppRoutes.Login);
        }
    }
}
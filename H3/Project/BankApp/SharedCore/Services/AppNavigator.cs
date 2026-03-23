using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using System.Reflection;
using SharedCore.Data;
using SharedCore.Entities.Auth;

namespace SharedCore.Services;

public interface IAppNavigator
{
    Task NavigateTo(string route);
}

public class AppNavigator(NavigationManager nav, AuthenticationStateProvider auth) : IAppNavigator
{
    public async Task NavigateTo(string route)
    {
        route = string.IsNullOrEmpty(route) ? AppRoutes.Index : route;
        var field = typeof(AppRoutes).GetFields(BindingFlags.Public | BindingFlags.Static)
            .FirstOrDefault(f => f.GetValue(null)?.ToString() == route);

        var requiredAttr = field?.GetCustomAttribute<RouteRoleAttribute>();

        if (requiredAttr == null)
        {
            nav.NavigateTo(route);
            return;
        }

        var state = await auth.GetAuthenticationStateAsync();
        var user = state.User;

        if (user.Identity?.IsAuthenticated != true)
        {
            nav.NavigateTo(AppRoutes.Login);
            return;
        }

        if (user.IsInRole(RoleType.Admin.ToString()) || user.IsInRole(requiredAttr.Role.ToString()))
        {
            nav.NavigateTo(route);
        }
        else
        {
            nav.NavigateTo("/error/403");
        }
    }
}
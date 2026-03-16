using SharedCore.Entities.Auth;

namespace SharedCore.Data;

[AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
public class RouteRoleAttribute(RoleType role) : Attribute
{
    public RoleType Role => role;
}

public static class AppRoutes
{
    public const string Index = "/";
    public const string Account = "/account";
    public const string Login = "/login";
    public const string Invest = "/invest";
    public const string LoginRegister = "/login/register";
    public const string LoginReset = "/login/reset";
    public const string Dashboard = "/dashboard";
    public const string Market = "/market";
    public const string Portfolio = "/portfolio";

    [RouteRole(RoleType.LoanOfficer)]
    public const string OfficerPanel = "/officer/panel";

    [RouteRole(RoleType.Admin)]
    public const string AdminTerminal = "/admin/terminal";
}
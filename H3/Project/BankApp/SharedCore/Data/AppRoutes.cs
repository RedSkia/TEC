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
    public const string LoginRegister = "/login/register";
    public const string LoginReset = "/login/reset";
    public const string Dashboard = "/dashboard";
    public const string Market = "/market";

    public const string ApiCheckout = "/api/checkout";

    [RouteRole(RoleType.LoanOfficer)] public const string OfficerLending = "/officer/lending";

    [RouteRole(RoleType.Admin)] public const string AdminMarketControl = "/admin/marketcontrol";
    [RouteRole(RoleType.Admin)] public const string AdminUserManagement = "/admin/usermanagement";
}
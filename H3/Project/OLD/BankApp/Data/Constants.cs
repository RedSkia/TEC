using BankApp.Data.Entities.Auth;
using Microsoft.AspNetCore.Authorization;

namespace BankApp.Data.Constants;


[AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
public class RouteRoleAttribute(RoleType role) : Attribute
{
    public RoleType Role => role;
}


public static class AppRoutes
{
    public const string Index = "/";
    public const string Login = "/login";
    public const string Register = "/register";
    public const string Dashboard = "/dashboard"; // Publicly visible, but page-level auth handles it
    public const string Market = "/market";
    public const string Portfolio = "/portfolio";

    [RouteRole(RoleType.LoanOfficer)]
    public const string OfficerPanel = "/officer/panel";

    [RouteRole(RoleType.Admin)]
    public const string AdminTerminal = "/admin/terminal";
}


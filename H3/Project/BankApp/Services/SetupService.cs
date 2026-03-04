using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Market;
using Microsoft.AspNetCore.Components.Authorization;

namespace BankApp.Services;

public static class SetupService
{
    public static IServiceCollection AddProjectServices(this IServiceCollection services)
    {
        services.AddHttpContextAccessor();

        // Auth Engine
        services.AddScoped<TokenStorageService>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IAuthService, AuthService>();

        // Custom Auth State
        services.AddScoped<JwtAuthStateProvider>();
        services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<JwtAuthStateProvider>());
        services.AddCascadingAuthenticationState();
        services.AddAuthorizationCore();

        // CRUD Services
        services.AddScoped<ICRUDService<Stock>, CRUDService<Stock>>();
        services.AddScoped<ICRUDService<ExchangeRate>, CRUDService<ExchangeRate>>();
        services.AddScoped<ICRUDService<Card>, CRUDService<Card>>();
        services.AddScoped<ICRUDService<Transaction>, CRUDService<Transaction>>();
        services.AddScoped<ICRUDService<Address>, CRUDService<Address>>();
        services.AddScoped<ICRUDService<LoginActivity>, CRUDService<LoginActivity>>();
        services.AddScoped<ICRUDService<BankAccount>, CRUDService<BankAccount>>();
        services.AddScoped<ICRUDService<LoanRequest>, CRUDService<LoanRequest>>();
        services.AddScoped<ICRUDService<Investment>, CRUDService<Investment>>();

        return services;
    }
}
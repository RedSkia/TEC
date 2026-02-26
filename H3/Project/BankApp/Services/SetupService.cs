using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Market;

namespace BankApp.Services;

public static class SetupService
{
    public static IServiceCollection AddProjectServices(this IServiceCollection services)
    {
        // 1. Specielle Business Services (Dem du selv har bygget)
        services.AddHttpContextAccessor();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<AuthService>();

        // 2. Den Generiske CRUD Motor (Alle dine tabeller)
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
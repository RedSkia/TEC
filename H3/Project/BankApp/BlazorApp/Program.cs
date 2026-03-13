using BankApp.Data;
using BankApp.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using BankApp.Data.Entities.Market;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Lending;
using Microsoft.EntityFrameworkCore.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// --- 1. DATABASE & IDENTITY ---
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContextFactory<BankAppDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
        sqlOptions.EnableRetryOnFailure(5, TimeSpan.FromSeconds(10), null);
    });
    // CRITICAL: Suppress the error that stops the database from creating/migrating
    options.ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning));
});

builder.Services.AddIdentity<ApplicationUser, ApplicationRole>(options => {
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 1;
    options.Password.RequiredUniqueChars = 0;
    options.Password.RequireLowercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
})
.AddEntityFrameworkStores<BankAppDbContext>()
.AddDefaultTokenProviders();

builder.Services.AddScoped(sp =>
    sp.GetRequiredService<IDbContextFactory<BankAppDbContext>>().CreateDbContext());

// --- 2. AUTHENTICATION ---
builder.Services.AddAuthentication(options => {
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options => {
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidIssuer = builder.Configuration["JWT:Issuer"],
        ValidAudience = builder.Configuration["JWT:Audience"],
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["JWT:Key"]!)),
        ClockSkew = TimeSpan.FromSeconds(30)
    };
});

// --- 3. SERVICES ---
builder.Services.AddHttpContextAccessor();
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddControllers();
builder.Services.AddRazorComponents().AddInteractiveServerComponents();

builder.Services.AddScoped<TokenStorageService>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IRouteNavigator, RouteNavigator>();
builder.Services.AddScoped<ICurrencyService, CurrencyService>();
builder.Services.AddScoped<ILendingService, LendingService>();
builder.Services.AddScoped<ITransferService, TransferService>();
builder.Services.AddSingleton<IStockService, StockService>();
builder.Services.AddHostedService<MarketWorker>();


builder.Services.AddScoped<JwtAuthStateProvider>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<JwtAuthStateProvider>());

builder.Services.AddAuthorizationCore(options => {
    options.DefaultPolicy = new AuthorizationPolicyBuilder(JwtBearerDefaults.AuthenticationScheme)
        .RequireAuthenticatedUser().Build();
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("StaffOnly", policy => policy.RequireRole("Admin", "LoanOfficer"));
});

// CRUD
builder.Services.AddTransient<ICRUDService<Stock>, CRUDService<Stock>>();
builder.Services.AddTransient<ICRUDService<CurrencyType>, CRUDService<CurrencyType>>();
builder.Services.AddTransient<ICRUDService<Transaction>, CRUDService<Transaction>>();
builder.Services.AddTransient<ICRUDService<Address>, CRUDService<Address>>();
builder.Services.AddTransient<ICRUDService<LoginActivity>, CRUDService<LoginActivity>>();
builder.Services.AddTransient<ICRUDService<BankAccount>, CRUDService<BankAccount>>();
builder.Services.AddTransient<ICRUDService<LoanRequest>, CRUDService<LoanRequest>>();
builder.Services.AddTransient<ICRUDService<Investment>, CRUDService<Investment>>();

var app = builder.Build();

// --- 4. MIGRATION & SEEDING ---
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var contextFactory = services.GetRequiredService<IDbContextFactory<BankAppDbContext>>();
    var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

    int retryCount = 12; // 1 minute total
    while (retryCount > 0)
    {
        try
        {
            using var context = contextFactory.CreateDbContext();
            await context.Database.MigrateAsync();

            var adminName = "admin";
            var adminUser = await userManager.FindByNameAsync(adminName);
            if (adminUser == null)
            {
                var admin = new ApplicationUser { UserName = adminName, Email = "admin@bank.com", FullName = "System Admin", EmailConfirmed = true };
                var res = await userManager.CreateAsync(admin, "1");
                if (res.Succeeded)
                {
                    await userManager.AddToRoleAsync(admin, "Admin");
                    context.Addresses.Add(new Address { Street = "System", City = "System", ZipCode = "0000", UserId = admin.Id });
                    context.BankAccounts.Add(new BankAccount { AccountNumber = "ADM-001", Balance = 1000000, CurrencyTypeId = 1, UserId = admin.Id });
                    await context.SaveChangesAsync();
                }
            }
            Console.WriteLine(">>> Database Online and Seeded.");
            break;
        }
        catch (Exception ex)
        {
            retryCount--;
            Console.WriteLine($">>> DB Waiting... {retryCount} left. Error: {ex.Message}");
            await Task.Delay(5000);
        }
    }
}

// --- 5. MIDDLEWARE ---
app.UseStaticFiles();
app.UseAntiforgery();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapRazorComponents<BlazorApp.Components.App>().AddInteractiveServerRenderMode();

app.Run();
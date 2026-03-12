using BankApp.Data;
using BankApp.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Authorization; // Added
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using BankApp.Data.Entities.Market;
using BankApp.Data.Entities.Banking;

var builder = WebApplication.CreateBuilder(args);

// --- 1. DATABASE & IDENTITY FOUNDATION ---
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContextFactory<BankAppDbContext>(options =>
    options.UseSqlServer(connectionString, o =>
        o.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery)));

builder.Services.AddIdentity<ApplicationUser, ApplicationRole>(options =>
{
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

// --- 2. AUTHENTICATION (JWT) ---
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
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

// --- 3. PROJECT SERVICES ---
builder.Services.AddHttpContextAccessor();
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddControllers();
builder.Services.AddRazorComponents().AddInteractiveServerComponents();

builder.Services.AddScoped<TokenStorageService>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IRouteNavigator, RouteNavigator>();
builder.Services.AddScoped<ICurrencyService, CurrencyService>();
builder.Services.AddScoped<ITransferService, TransferService>();

builder.Services.AddScoped<JwtAuthStateProvider>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp =>
    sp.GetRequiredService<JwtAuthStateProvider>());

// --- UPDATED AUTHORIZATION POLICIES ---
builder.Services.AddAuthorizationCore(options =>
{
    // FIX: This ensures [Authorize] attributes use the JWT scheme
    options.DefaultPolicy = new AuthorizationPolicyBuilder(JwtBearerDefaults.AuthenticationScheme)
        .RequireAuthenticatedUser()
        .Build();

    options.AddPolicy("AdminOnly", policy => policy.RequireRole(RoleType.Admin.ToString()));
    options.AddPolicy("StaffOnly", policy => policy.RequireRole(RoleType.Admin.ToString(), RoleType.LoanOfficer.ToString()));
});

// CRUD Services
builder.Services.AddTransient<ICRUDService<Stock>, CRUDService<Stock>>();
builder.Services.AddTransient<ICRUDService<CurrencyType>, CRUDService<CurrencyType>>();
builder.Services.AddTransient<ICRUDService<Transaction>, CRUDService<Transaction>>();
builder.Services.AddTransient<ICRUDService<Address>, CRUDService<Address>>();
builder.Services.AddTransient<ICRUDService<LoginActivity>, CRUDService<LoginActivity>>();
builder.Services.AddTransient<ICRUDService<BankAccount>, CRUDService<BankAccount>>();
builder.Services.AddTransient<ICRUDService<LoanRequest>, CRUDService<LoanRequest>>();
builder.Services.AddTransient<ICRUDService<Investment>, CRUDService<Investment>>();

// --- 4. DATA PROTECTION ---
var keysPath = "/app/temp-keys";
if (!Directory.Exists(keysPath)) Directory.CreateDirectory(keysPath);
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(keysPath))
    .SetApplicationName("BankApp");

var app = builder.Build();

// --- 5. DB AUTO-MIGRATION & SEEDING ---
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var contextFactory = services.GetRequiredService<IDbContextFactory<BankAppDbContext>>();
    int retryCount = 15;

    while (retryCount > 0)
    {
        try
        {
            using var context = contextFactory.CreateDbContext();
            await context.Database.MigrateAsync();

            var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = services.GetRequiredService<RoleManager<ApplicationRole>>();

            if (!await roleManager.RoleExistsAsync(RoleType.Admin.ToString()))
            {
                await roleManager.CreateAsync(new ApplicationRole
                {
                    Name = RoleType.Admin.ToString(),
                    RoleColor = "#FF0000"
                });
            }

            var adminName = RoleType.Admin.ToString().ToLowerInvariant();
            var adminUser = await userManager.FindByNameAsync(adminName);
            if (adminUser == null)
            {
                var newAdmin = new ApplicationUser
                {
                    UserName = adminName,
                    Email = "admin@bank.com",
                    FullName = "System Admin",
                    EmailConfirmed = true
                };
                await userManager.CreateAsync(newAdmin, "1");
                await userManager.AddToRoleAsync(newAdmin, RoleType.Admin.ToString());
            }
            break;
        }
        catch (Exception ex)
        {
            retryCount--;
            Console.WriteLine($">>> Database connecting... {retryCount} attempts left.");
            await Task.Delay(5000);
        }
    }
}

// --- 6. MIDDLEWARE ---
app.UseStaticFiles();
app.UseAntiforgery();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapRazorComponents<BlazorApp.Components.App>()
   .AddInteractiveServerRenderMode();

app.Run();
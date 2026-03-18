using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Threading.Tasks;
using SharedCore.Data;
using Microsoft.EntityFrameworkCore;
using SharedCore.Entities.Auth;
using SharedCore.Services;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Rewrite;

var builder = WebApplication.CreateBuilder(args);

// -----------------------------------------------------
// DATABASE
// -----------------------------------------------------
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContextFactory<BankAppDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
        sqlOptions.EnableRetryOnFailure(5, TimeSpan.FromSeconds(10), null);
    });

    options.ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning));
});

// -----------------------------------------------------
// IDENTITY
// -----------------------------------------------------
builder.Services.AddIdentityCore<ApplicationUser>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 1;
    options.Password.RequiredUniqueChars = 0;
    options.Password.RequireLowercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.User.RequireUniqueEmail = true;
})
.AddRoles<ApplicationRole>()
.AddEntityFrameworkStores<BankAppDbContext>()
.AddDefaultTokenProviders();

// -----------------------------------------------------
// JWT AUTHENTICATION
// -----------------------------------------------------
var jwtKey = builder.Configuration["JWT:Key"]!;
var jwtIssuer = builder.Configuration["JWT:Issuer"]!;
var jwtAudience = builder.Configuration["JWT:Audience"]!;

builder.Services
.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var token = context.Request.Query["access_token"];
            if (!string.IsNullOrEmpty(token) && context.HttpContext.Request.Path.StartsWithSegments("/_blazor"))
            {
                context.Token = token;
            }
            return Task.CompletedTask;
        }
    };
});

// -----------------------------------------------------
// CORS & CONTROLLERS (THE GATEWAY ADDITIONS)
// -----------------------------------------------------
// 1. Allows your external HTML lab to make POST requests
builder.Services.AddCors(options => {
    options.AddDefaultPolicy(policy => {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});

// 2. Registers your CheckoutController
builder.Services.AddControllers();

// -----------------------------------------------------
// AUTHORIZATION & ANTIFORGERY
// -----------------------------------------------------
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", p => p.RequireRole("Admin"));
    options.AddPolicy("StaffOnly", p => p.RequireRole("Admin", "LoanOfficer"));
});

builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-TOKEN";
});

// -----------------------------------------------------
// BLAZOR & CUSTOM SERVICES
// -----------------------------------------------------
builder.Services.AddHttpContextAccessor();
builder.Services.AddRazorComponents().AddInteractiveServerComponents();

builder.Services.AddCascadingAuthenticationState();

// 3. FIX: Registers the default HttpClient for your Blazor pages and Webhooks
builder.Services.AddHttpClient();

builder.Services.AddScoped<AuthenticationStateProvider, IdentityService>();
builder.Services.AddScoped<IdentityService>();
builder.Services.AddScoped<AppNavigator>();
builder.Services.AddScoped<FinanceService>();
builder.Services.AddSingleton<StockMarketService>();
builder.Services.AddHostedService(sp => sp.GetRequiredService<StockMarketService>());

var app = builder.Build();

// -----------------------------------------------------
// DATABASE MIGRATION + SEEDING
// -----------------------------------------------------
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var contextFactory = services.GetRequiredService<IDbContextFactory<BankAppDbContext>>();
    var roleManager = services.GetRequiredService<RoleManager<ApplicationRole>>();
    var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

    using var context = contextFactory.CreateDbContext();
    await context.Database.MigrateAsync();

    if (!await roleManager.RoleExistsAsync("Admin"))
        await roleManager.CreateAsync(new ApplicationRole { Name = "Admin", RoleColor = "#c80000" });

    if (!await roleManager.RoleExistsAsync("LoanOfficer"))
        await roleManager.CreateAsync(new ApplicationRole { Name = "LoanOfficer", RoleColor = "#00c800" });

    if (!await roleManager.RoleExistsAsync("Customer"))
        await roleManager.CreateAsync(new ApplicationRole { Name = "Customer", RoleColor = "#00c8c8" });

    var admin = await userManager.FindByNameAsync("admin");
    if (admin == null)
    {
        admin = new ApplicationUser
        {
            UserName = "admin",
            Email = "admin@bank.com",
            FullName = "System Admin",
            EmailConfirmed = true
        };

        var result = await userManager.CreateAsync(admin, "1");
        if (result.Succeeded)
            await userManager.AddToRoleAsync(admin, "Admin");
    }
}

// -----------------------------------------------------
// MIDDLEWARE PIPELINE
// -----------------------------------------------------
app.UseCors(); // 4. FIX: Must be placed early in the pipeline


// 2. ADD THIS URL REWRITE BLOCK
var rewriteOptions = new RewriteOptions()
    // ^api/checkout/?$ ensures it ONLY matches the exact path.
    // If there is an ID after it (e.g., api/checkout/guid), this rule is skipped.
    .AddRewrite(@"^api/checkout/?$", "api/checkout.html", skipRemainingRules: true);

app.UseRewriter(rewriteOptions);

app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.UseAntiforgery();

app.MapControllers(); // 5. FIX: Exposes the API endpoints

app.MapRazorComponents<BlazorApp.Components.App>()
   .AddInteractiveServerRenderMode();

app.Run();
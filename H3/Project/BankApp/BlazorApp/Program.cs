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
using SharedCore.Entities.Banking;
using Microsoft.AspNetCore.Http;

var builder = WebApplication.CreateBuilder(args);

// -----------------------------------------------------
// 1. DATABASE CONFIGURATION (Using Factory)
// -----------------------------------------------------
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContextFactory<BankAppDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
        sqlOptions.EnableRetryOnFailure(5, TimeSpan.FromSeconds(10), null);
    });
    // Ignore warning about pending model changes during development
    options.ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning));
});

// -----------------------------------------------------
// 2. IDENTITY SYSTEM
// -----------------------------------------------------
builder.Services.AddIdentityCore<ApplicationUser>(options =>
{
    // Minimal security requirements as requested
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
// 3. JWT AUTHENTICATION SETUP
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
            // Allow token retrieval from query string for Blazor signalR connections
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
// 4. CORE WEB SERVICES
// -----------------------------------------------------
builder.Services.AddCors(options => {
    options.AddDefaultPolicy(policy => {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});

builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor(); // REQUIRED for IdentityService to see IP/UserAgent

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
// 5. BLAZOR & CUSTOM SERVICES
// -----------------------------------------------------
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddHttpClient();

// Custom Application Services
builder.Services.AddScoped<IdentityService>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<IdentityService>());

builder.Services.AddScoped<AppNavigator>();
builder.Services.AddScoped<FinanceService>();
builder.Services.AddSingleton<StockMarketService>();
builder.Services.AddHostedService(sp => sp.GetRequiredService<StockMarketService>());

var app = builder.Build();

// -----------------------------------------------------
// 6. DATABASE MIGRATION & SEEDING (Using Factory)
// -----------------------------------------------------
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var contextFactory = services.GetRequiredService<IDbContextFactory<BankAppDbContext>>();
    var roleManager = services.GetRequiredService<RoleManager<ApplicationRole>>();
    var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

    using var context = contextFactory.CreateDbContext();
    await context.Database.MigrateAsync();

    // Seed Roles
    string[] roles = { "Admin", "LoanOfficer", "Customer" };
    string[] colors = { "#c80000", "#00c800", "#00c8c8" };

    for (int i = 0; i < roles.Length; i++)
    {
        if (!await roleManager.RoleExistsAsync(roles[i]))
        {
            await roleManager.CreateAsync(new ApplicationRole { Name = roles[i], RoleColor = colors[i] });
        }
    }

    // Seed Admin User
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
// 7. MIDDLEWARE PIPELINE
// -----------------------------------------------------
app.UseCors();

// API Rewrite Rules
var rewriteOptions = new RewriteOptions()
    .AddRewrite(@"^api/checkout/?$", "api/checkout.html", skipRemainingRules: true);

app.UseRewriter(rewriteOptions);

app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.UseAntiforgery();

app.MapControllers();

app.MapRazorComponents<BlazorApp.Components.App>()
   .AddInteractiveServerRenderMode();

app.Run();
using BankApp.Data;
using BlazorApp.Components;
using BankApp.Data.Entities.Auth;
using BankApp.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.DataProtection;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// --- 1. DATABASE SETUP ---

var connectionString = builder.Configuration.GetConnectionString("ProdConnection");
builder.Services.AddDbContextFactory<BankAppDbContext>(options =>
    options.UseSqlServer(connectionString, o =>
        o.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery)));

// --- 2. IDENTITY SETUP ---
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

// --- 3. JWT & AUTHENTICATION ---
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

// --- 4. DATA PROTECTION (Persistent Keys) ---
// Using absolute path /app/temp-keys to match the Docker Volume mount
var keysPath = "/app/temp-keys";
if (!Directory.Exists(keysPath)) Directory.CreateDirectory(keysPath);

builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(keysPath))
    .SetApplicationName("BankApp");

builder.Services.AddProjectServices();
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddControllers();

var app = builder.Build();

// --- 5. DATABASE AUTO-SETUP ---
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
                await roleManager.CreateAsync(new ApplicationRole { Name = RoleType.Admin.ToString(), RoleColor = "#FF0000" });
            }

            var adminUser = await userManager.FindByNameAsync(RoleType.Admin.ToString().ToLowerInvariant());
            if (adminUser == null)
            {
                var newAdmin = new ApplicationUser { UserName = RoleType.Admin.ToString().ToLowerInvariant(), Email = "admin@bank.com", FullName = RoleType.Admin.ToString(), EmailConfirmed = true };
                await userManager.CreateAsync(newAdmin, "1");
                await userManager.AddToRoleAsync(newAdmin, RoleType.Admin.ToString());
                Console.WriteLine(">>> Admin Seeded: admin / 1");
            }
            break;
        }
        catch (Exception ex)
        {
            retryCount--;
            Console.WriteLine($">>> DB Wait... {ex.Message}");
            await Task.Delay(5000);
        }
    }
}

app.UseStatusCodePagesWithReExecute("/error/{0}");
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseStaticFiles();
app.UseAntiforgery();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapRazorComponents<App>().AddInteractiveServerRenderMode();

app.Run();
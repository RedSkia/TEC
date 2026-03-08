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

            if (!await roleManager.RoleExistsAsync("Admin"))
            {
                await roleManager.CreateAsync(new ApplicationRole { Name = "Admin", RoleColor = "#FF0000" });
            }

            var adminUser = await userManager.FindByNameAsync("admin");
            if (adminUser == null)
            {
                var newAdmin = new ApplicationUser { UserName = "admin", Email = "admin@bank.com", FullName = "Admin", EmailConfirmed = true };
                await userManager.CreateAsync(newAdmin, "Passw0rd123!");
                await userManager.AddToRoleAsync(newAdmin, "Admin");
                Console.WriteLine(">>> Admin Seeded: admin / Passw0rd123!");
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
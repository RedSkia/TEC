using BankApp.Components;
using BankApp.Data;
using BankApp.Data.Entities.Auth;
using BankApp.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// --- 1. DATABASE SETUP ---
var connectionString = builder.Configuration.GetConnectionString("ProdConnection");
builder.Services.AddDbContextFactory<BankAppDbContext>(options =>
    options.UseSqlServer(connectionString, o =>
        o.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery)));

// --- 2. IDENTITY SETUP ---
builder.Services.AddIdentityCore<ApplicationUser>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 1;
    options.Password.RequiredUniqueChars = 0;
    options.Password.RequireLowercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
})
.AddRoles<ApplicationRole>()
.AddRoleManager<RoleManager<ApplicationRole>>()
.AddEntityFrameworkStores<BankAppDbContext>()
.AddDefaultTokenProviders();

// --- 3. JWT & AUTHENTICATION ---
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
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

// --- 4. BLAZOR AUTHENTICATION BRIDGE ---
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddScoped<JwtAuthStateProvider>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<JwtAuthStateProvider>());
builder.Services.AddAuthorization();

// --- 5. PROJECT SERVICES ---
builder.Services.AddProjectServices();

// --- 6. UI & API ---
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();
builder.Services.AddControllers();

var app = builder.Build();

// --- 7. SEEDING (THE "ONLY ONE ADMIN" LOGIC) ---
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = services.GetRequiredService<RoleManager<ApplicationRole>>();

        // 1. Ensure Admin Role exists
        if (!await roleManager.RoleExistsAsync(RoleType.Admin.ToString()))
        {
            await roleManager.CreateAsync(new ApplicationRole { Name = RoleType.Admin.ToString(), RoleColor = "#FF0000" });
        }

        // 2. Get all Admins
        var admins = await userManager.GetUsersInRoleAsync(RoleType.Admin.ToString());

        if (admins.Count == 0)
        {
            // Create the default admin if none exist
            var defaultAdmin = new ApplicationUser
            {
                UserName = "admin",
                Email = "admin@bank.com",
                FullName = "System Administrator",
                EmailConfirmed = true
            };
            await userManager.CreateAsync(defaultAdmin, "!");
            await userManager.AddToRoleAsync(defaultAdmin, RoleType.Admin.ToString());
        }
        else if (admins.Count > 1)
        {
            // Keep the one with the lowest ID (oldest), delete the rest
            var sortedAdmins = admins.OrderBy(u => u.Id).ToList();
            var primaryAdmin = sortedAdmins.First();
            var duplicates = sortedAdmins.Skip(1);

            foreach (var redundantAdmin in duplicates)
            {
                await userManager.DeleteAsync(redundantAdmin);
            }
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Seeding Error: {ex.Message}");
    }
}

app.UseStatusCodePagesWithReExecute("/error/{0}");

// --- 8. MIDDLEWARE ---
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseAntiforgery();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
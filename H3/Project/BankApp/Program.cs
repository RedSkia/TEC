using BankApp.Components;
using BankApp.Data;
using BankApp.Data.Entities.Auth;
using BankApp.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// --- 1. DATABASE SETUP (With Split Query Fix) ---
var connectionString = builder.Configuration.GetConnectionString("ProdConnection");

builder.Services.AddDbContext<BankAppDbContext>(options =>
    options.UseSqlServer(connectionString, o =>
        o.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery))); // FIX 1: Performance

// --- 2. IDENTITY SETUP (Fixed Role Management) ---
builder.Services.AddIdentityCore<ApplicationUser>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
})
.AddRoles<ApplicationRole>() // Required for your RoleType logic
.AddRoleManager<RoleManager<ApplicationRole>>() // FIX 2: Needed for AddToRoleAsync
.AddEntityFrameworkStores<BankAppDbContext>()
.AddDefaultTokenProviders();

// --- 3. JWT & AUTHENTICATION ---
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var key = Encoding.UTF8.GetBytes(builder.Configuration["JWT:Key"]!);
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidIssuer = builder.Configuration["JWT:Issuer"],
            ValidAudience = builder.Configuration["JWT:Audience"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ClockSkew = TimeSpan.FromSeconds(30) // FIX 3: Prevents instant expiry if clocks differ
        };
    });

builder.Services.AddAuthorization();

// --- 4. PROJECT SERVICES ---
builder.Services.AddProjectServices();

// --- 5. UI & API ---
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddControllers();

// ADD THIS LINE HERE:
builder.Services.AddCascadingAuthenticationState();

var app = builder.Build();

// --- 6. DATABASE SEEDING (Lightweight Version) ---
using (var scope = app.Services.CreateScope())
{
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

    async Task SeedUser(string email, string name, string pass, RoleType role)
    {
        if (await userManager.FindByEmailAsync(email) == null)
        {
            var user = new ApplicationUser
            {
                UserName = email,
                Email = email,
                FullName = name,
                EmailConfirmed = true
            };
            var result = await userManager.CreateAsync(user, pass);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(user, role.ToString());
            }
        }
    }

    await SeedUser("admin@bank.dk", "System Admin", "Admin123!", RoleType.Admin);
    await SeedUser("officer@bank.dk", "Lånebehandler", "Officer123!", RoleType.LoanOfficer);
}

// --- 7. MIDDLEWARE ---
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseAuthentication(); // Must be before Authorization
app.UseAuthorization();
app.UseAntiforgery();

app.MapControllers();
app.MapRazorComponents<App>().AddInteractiveServerRenderMode();

app.Run();
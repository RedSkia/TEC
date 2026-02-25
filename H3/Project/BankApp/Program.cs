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

// --- 1. DATABASE SETUP ---
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=localhost;Database=BankAppDb;User Id=sa;Password=Pa$$w0rd!;TrustServerCertificate=True";

builder.Services.AddDbContext<BankAppDbContext>(options =>
    options.UseSqlServer(connectionString));

// --- 2. IDENTITY SETUP ---
builder.Services.AddIdentityCore<ApplicationUser>(options => {
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
})
.AddRoles<ApplicationRole>()
.AddEntityFrameworkStores<BankAppDbContext>()
.AddDefaultTokenProviders();

// --- 3. JWT & AUTHORIZATION ---
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
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// --- 4. CUSTOM PROJECT SERVICES ---
// Her kalder vi din extension method fra SetupService.cs
builder.Services.AddProjectServices();

// --- 5. UI & API SETUP ---
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddControllers();

var app = builder.Build();

// --- 6. DATABASE INITIALIZATION (SEEDING) ---
using (var scope = app.Services.CreateScope())
{
    var authService = scope.ServiceProvider.GetRequiredService<AuthService>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

    if (await userManager.FindByEmailAsync("admin@bank.dk") == null)
        await authService.Register("admin@bank.dk", "Admin123!", "System Admin", RoleType.Admin);

    if (await userManager.FindByEmailAsync("officer@bank.dk") == null)
        await authService.Register("officer@bank.dk", "Officer123!", "Lånebehandler", RoleType.LoanOfficer);
}

// --- 7. PIPELINE / MIDDLEWARE ---
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();
app.UseAntiforgery();

app.MapControllers();
app.MapRazorComponents<App>().AddInteractiveServerRenderMode();

app.Run();
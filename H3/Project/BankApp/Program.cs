using BankApp.Components;
using BankApp.Data;
using BankApp.Entities.Auth;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// 1. DATABASE SETUP (Docker SQL Server)
// Erstat connection string med din egen fra appsettings.json
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=localhost;Database=BankAppDb;User Id=sa;Password=Pa$$w0rd!;TrustServerCertificate=True";

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// 2. IDENTITY SETUP (Uden standard UI, da vi bruger Blazor)
builder.Services.AddIdentityCore<AuthUser>(options => {
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
})
.AddRoles<IdentityRole>()
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();

// 3. JWT SIKKERHED
const string JWTKey = "SuperSecretKey12345_Skal_Vaere_Lang_Nok"; // Brug en længere nøgle i prod

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(JWTKey))
    };
});

builder.Services.AddAuthorization();

// 4. DINE EGNE SERVICES
//builder.Services.AddScoped<AuthService>();
//builder.Services.AddScoped<AccountService>();
//builder.Services.AddScoped<TransactionService>();
//builder.Services.AddScoped<UserSession>();

// 5. BLAZOR SETUP
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// 6. API & CONTROLLERS (Til dit Public WebAPI)
builder.Services.AddControllers();

var app = builder.Build();

// PIPELINE KONFIGURATION
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles(); // Vigtigt for CSS/JS

// VIGTIGT: Rækkefølgen her er kritisk!
app.UseAuthentication();
app.UseAuthorization();

app.UseAntiforgery();

// Map dine Public API Controllers
app.MapControllers();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();


/* SPA
    JWT Login
    2 Lag sikkerhed: 
    Public WebAPI 
    CRUD
    NUnit



JWT Login
Roles (User, Admin)
AccountHolder -> BankAccount -> UserAccount -> AuthAccount
Cards 
Invesnting (RandomGrapths)
Transtations -> Transfer,Withdraw,Add,Loan
Loan -> intrest rates
 */
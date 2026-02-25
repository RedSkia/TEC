using BankApp.Components;
using BankApp.Data;
using BankApp.Data.Entities.Auth;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// 1. DATABASE SETUP (Docker SQL Server)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=localhost;Database=BankAppDb;User Id=sa;Password=Pa$$w0rd!;TrustServerCertificate=True";

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// 2. IDENTITY SETUP (Opdateret til at matche din arkitektur)
builder.Services.AddIdentityCore<ApplicationUser>(options => {
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
})
.AddRoles<ApplicationRole>() // Bruger din custom ApplicationRole (Admin, LoanOfficer, Customer)
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();

// 3. JWT SIKKERHED
// HUSK: I produktion skal denne nøgle gemmes sikkert (User Secrets/Environment Variables)
const string JWTKey = "Dette_Er_En_Meget_Lang_Og_Sikker_Noegle_Til_JWT_123456";

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
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(JWTKey)),
        ClockSkew = TimeSpan.Zero // Sikrer præcis udløb af tokens
    };
});

builder.Services.AddAuthorization();

// 4. DINE EGNE SERVICES (Klar til implementering)
// builder.Services.AddScoped<AuthService>();
// builder.Services.AddScoped<AccountService>();
// builder.Services.AddScoped<LoanTicketService>(); // Din LoanTicket-fokuserede service

// 5. BLAZOR SETUP
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// 6. API & CONTROLLERS (Til dit Public WebAPI og SPA logik)
builder.Services.AddControllers();

var app = builder.Build();

// PIPELINE KONFIGURATION
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

// VIGTIGT: Authentication skal altid komme før Authorization
app.UseAuthentication();
app.UseAuthorization();

app.UseAntiforgery();

// Map dine API Controllers (vigtigt for JWT flowet)
app.MapControllers();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
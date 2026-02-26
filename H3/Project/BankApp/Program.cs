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
var connectionString = builder.Configuration.GetConnectionString("ProdConnection");

builder.Services.AddDbContext<BankAppDbContext>(options =>
    options.UseSqlServer(connectionString));

// --- 2. IDENTITY SETUP ---
builder.Services.AddIdentityCore<ApplicationUser>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
})
.AddRoles<ApplicationRole>()
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
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

// --- 4. PROJECT SERVICES ---
builder.Services.AddProjectServices(); // registers AuthService, TokenService, etc.

// --- 5. UI & API ---
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddControllers();

var app = builder.Build();

// --- 6. DATABASE SEEDING ---
using (var scope = app.Services.CreateScope())
{
    var authService = scope.ServiceProvider.GetRequiredService<IAuthService>();

    // Seed admin
    if (await authService.Login("admin@bank.dk", "Admin123!") == null)
    {
        await authService.Register("admin@bank.dk", "Admin123!", "System Admin", RoleType.Admin);
    }

    // Seed loan officer
    if (await authService.Login("officer@bank.dk", "Officer123!") == null)
    {
        await authService.Register("officer@bank.dk", "Officer123!", "Lånebehandler", RoleType.LoanOfficer);
    }
}

// --- 7. MIDDLEWARE ---
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
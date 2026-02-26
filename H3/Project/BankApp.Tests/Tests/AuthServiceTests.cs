using BankApp.Data.Entities.Auth;
using BankApp.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace BankApp.Tests;

[TestClass]
public class AuthServiceTests
{
    private AuthService _authService = null!;
    private UserManager<ApplicationUser> _userManager = null!;
    private BankApp.Data.BankAppDbContext _context = null!;

    [TestInitialize]
    public void Setup()
    {
        var config = TestFactory.GetConfig();
        _context = TestFactory.CreateDbContext(config);

        // Correctly typed UserStore for custom ApplicationRole
        var userStore = new UserStore<ApplicationUser, ApplicationRole, BankApp.Data.BankAppDbContext, string>(_context);

        _userManager = new UserManager<ApplicationUser>(
            userStore, null, new PasswordHasher<ApplicationUser>(),
            new IUserValidator<ApplicationUser>[0], new IPasswordValidator<ApplicationUser>[0],
            new UpperInvariantLookupNormalizer(), new IdentityErrorDescriber(), null, null);

        var tokenService = new TokenService(config);
        _authService = new AuthService(_userManager, tokenService);

        _context.Database.EnsureDeleted();
        _context.Database.EnsureCreated();
    }

    [TestMethod, Priority(3)]
    public async Task AuthService_Register_CreatesUsersForAllRolesInDatabase()
    {
        // Arrange
        var roles = Enum.GetValues<RoleType>();

        foreach (var role in roles)
        {
            var email = $"reg_{role.ToString().ToLower()}@test.dk";
            var password = "Password123!";
            var name = $"{role} Registration Test";

            // Act
            var result = await _authService.Register(email, password, name, role);

            // Assert
            Assert.IsTrue(result, $"Register failed for role: {role}");

            var user = await _userManager.FindByEmailAsync(email);
            Assert.IsNotNull(user, $"User for {role} was not saved to SQL.");

            var isInRole = await _userManager.IsInRoleAsync(user, role.ToString());
            Assert.IsTrue(isInRole, $"User was created but not assigned to {role} in AspNetUserRoles.");
        }
    }

    [TestMethod, Priority(3)]
    public async Task AuthService_Login_ReturnsValidJwtForExistingUsers()
    {
        // Arrange
        var roles = Enum.GetValues<RoleType>();
        var password = "Password123!";

        // Pre-create users so Login has something to work with
        foreach (var role in roles)
        {
            var email = $"login_{role.ToString().ToLower()}@test.dk";
            await _authService.Register(email, password, "Login Test User", role);
        }

        // Act & Assert
        foreach (var role in roles)
        {
            var email = $"login_{role.ToString().ToLower()}@test.dk";

            var token = await _authService.Login(email, password);

            Assert.IsNotNull(token, $"Login failed to return token for role: {role}");
            Assert.IsTrue(token.Split('.').Length == 3, "Returned token is not a valid JWT format.");
        }
    }

    [TestMethod, Priority(3)]
    public async Task AuthService_Login_ReturnsNullForInvalidCredentials()
    {
        // Act
        var result = await _authService.Login("nonexistent@test.dk", "WrongPassword123!");

        // Assert
        Assert.IsNull(result, "AuthService should return null for invalid credentials.");
    }

    [TestCleanup]
    public void Cleanup()
    {
        _context?.Dispose();
        _userManager?.Dispose();
    }
}
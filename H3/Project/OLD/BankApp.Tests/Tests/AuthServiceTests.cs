using BankApp.Data;
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
    private BankAppDbContext _context = null!;

    [TestInitialize]
    public void Setup()
    {
        var config = TestFactory.GetConfig();
        _context = TestFactory.CreateDbContext(config);

        // Setup Identity requirements: Store -> Manager -> Service
        var userStore = new UserStore<ApplicationUser, ApplicationRole, BankApp.Data.BankAppDbContext, string>(_context);

        _userManager = new UserManager<ApplicationUser>(
            userStore, null, new PasswordHasher<ApplicationUser>(),
            new IUserValidator<ApplicationUser>[0], new IPasswordValidator<ApplicationUser>[0],
            new UpperInvariantLookupNormalizer(), new IdentityErrorDescriber(), null, null);

        _authService = new AuthService(_userManager, new TokenService(config));

        // Ensure we start with a fresh, empty database schema
        _context.Database.EnsureDeleted();
        _context.Database.EnsureCreated();
    }

    [TestMethod]
    public async Task AuthService_Register_CreatesUsersForAllRolesInDatabase()
    {
        // Check that every role defined in RoleType can actually be registered
        foreach (var role in Enum.GetValues<RoleType>())
        {
            var email = $"reg_{role.ToString().ToLower()}@test.dk";
            var result = await _authService.Register(email, "Password123!", "Registration Test", role);

            // Assert: Registration succeeded and user exists in SQL with the correct role
            Assert.IsTrue(result, $"Register failed for: {role}");

            var user = await _userManager.FindByEmailAsync(email);
            Assert.IsNotNull(user, $"User {role} not found in database.");
            Assert.IsTrue(await _userManager.IsInRoleAsync(user, role.ToString()), $"Role assignment failed for {role}.");
        }
    }

    [TestMethod]
    public async Task AuthService_Login_ReturnsValidJwtForExistingUsers()
    {
        var password = "Password123!";

        // 1. Arrange: Seed a user for every role
        foreach (var role in Enum.GetValues<RoleType>())
        {
            var email = $"login_{role.ToString().ToLower()}@test.dk";
            await _authService.Register(email, password, "Login Test", role);
        }

        // 2. Act & Assert: Verify login produces a valid 3-part JWT
        foreach (var role in Enum.GetValues<RoleType>())
        {
            var email = $"login_{role.ToString().ToLower()}@test.dk";
            var token = await _authService.Login(email, password);

            Assert.IsNotNull(token, $"Login failed to return token for: {role}");
            Assert.AreEqual(3, token.Split('.').Length, "Token is not in valid JWT format (Header.Payload.Signature).");
        }
    }

    [TestMethod]
    public async Task AuthService_Login_ReturnsNullForInvalidCredentials()
    {
        // Act: Attempt login with non-existent credentials
        var result = await _authService.Login("nonexistent@test.dk", "WrongPassword123!");

        // Assert: Service should gracefully return null
        Assert.IsNull(result, "AuthService should return null for invalid credentials.");
    }

    [TestCleanup]
    public void Cleanup()
    {
        _context?.Dispose();
        _userManager?.Dispose();
    }
}
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.JSInterop;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using SharedCore.Data;
using SharedCore.Entities.Auth;
using SharedCore.Services;

namespace SharedCore.Tests.IntegrationTests;

[TestClass]
public class IdentityServiceIntegrationTests
{
    private SqliteConnection _connection = null!;
    private DbContextOptions<BankAppDbContext> _options = null!;
    private Mock<IDbContextFactory<BankAppDbContext>> _mockFactory = null!;
    private IdentityService _service = null!;

    [TestInitialize]
    public void Setup()
    {
        // 1. Unik isoleret database pr. test
        string uniqueDbName = Guid.NewGuid().ToString();
        _connection = new SqliteConnection($"DataSource=file:{uniqueDbName}?mode=memory&cache=shared");
        _connection.Open();

        _options = new DbContextOptionsBuilder<BankAppDbContext>()
            .UseSqlite(_connection)
            .Options;

        using (var context = new BankAppDbContext(_options))
        {
            context.Database.EnsureDeleted();
            context.Database.EnsureCreated();
        }

        _mockFactory = new Mock<IDbContextFactory<BankAppDbContext>>();
        _mockFactory.Setup(f => f.CreateDbContextAsync(It.IsAny<CancellationToken>()))
                    .ReturnsAsync(() => new BankAppDbContext(_options));

        // 2. Dummy dependencies til IdentityService (vi tester DB-kald her, ikke UserManager)
        var mockStore = new Mock<IUserStore<ApplicationUser>>();
        var mockUserManager = new Mock<UserManager<ApplicationUser>>(mockStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);
        var mockJsRuntime = new Mock<IJSRuntime>();
        var mockHttpAccessor = new Mock<IHttpContextAccessor>();
        var emptyConfig = new ConfigurationBuilder().Build();

        _service = new IdentityService(mockUserManager.Object, _mockFactory.Object, emptyConfig, mockJsRuntime.Object, mockHttpAccessor.Object);
    }

    [TestCleanup]
    public void Cleanup()
    {
        _connection.Close();
    }

    private async Task SeedUsersAsync()
    {
        using var db = new BankAppDbContext(_options);

        db.Users.Add(new ApplicationUser { Id = "u1", UserName = "admin", FullName = "Admin User" });
        db.Users.Add(new ApplicationUser { Id = "u2", UserName = "john", FullName = "John Doe" });
        db.Users.Add(new ApplicationUser { Id = "u3", UserName = "jane", FullName = "Jane Doe" });

        await db.SaveChangesAsync();
    }

    [TestMethod]
    public async Task GetAllUsersExceptAsync_ExcludesTargetUser()
    {
        // Arrange
        await SeedUsersAsync();

        // Act
        var users = await _service.GetAllUsersExceptAsync("u2");

        // Assert
        Assert.AreEqual(2, users.Count);
        Assert.IsFalse(users.Any(u => u.Id == "u2"));
        Assert.IsTrue(users.Any(u => u.Id == "u1"));
    }

    [TestMethod]
    public async Task UpdateUserProfileAsync_ValidUser_UpdatesNameAndAddress()
    {
        // Arrange
        await SeedUsersAsync();

        var updatedData = new ApplicationUser
        {
            FullName = "Johnny Updated",
            Address = new Address { Street = "Main St 1", City = "TestCity", ZipCode = "1234" }
        };

        // Act
        bool result = await _service.UpdateUserProfileAsync("u2", updatedData);

        // Assert
        Assert.IsTrue(result);

        using var db = new BankAppDbContext(_options);
        var userInDb = await db.Users.Include(u => u.Address).FirstAsync(u => u.Id == "u2");

        Assert.AreEqual("Johnny Updated", userInDb.FullName);
        Assert.IsNotNull(userInDb.Address);
        Assert.AreEqual("Main St 1", userInDb.Address.Street);
    }

    [TestMethod]
    public async Task UpdateUserProfileAsync_InvalidUser_ReturnsFalse()
    {
        // Arrange
        await SeedUsersAsync();
        var dummyData = new ApplicationUser { FullName = "Ghost" };

        // Act
        bool result = await _service.UpdateUserProfileAsync("ghost_id", dummyData);

        // Assert
        Assert.IsFalse(result);
    }
}
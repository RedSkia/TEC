using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.JSInterop;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using SharedCore.Data;
using SharedCore.Entities.Auth;
using SharedCore.Services;

namespace SharedCore.Tests.UnitTests;

[TestClass]
public class IdentityServiceUnitTests
{
    private Mock<UserManager<ApplicationUser>> _mockUserManager = null!;
    private Mock<IDbContextFactory<BankAppDbContext>> _mockDbFactory = null!;
    private Mock<IJSRuntime> _mockJsRuntime = null!;
    private Mock<IHttpContextAccessor> _mockHttpAccessor = null!;
    private IConfiguration _configuration = null!;
    private IdentityService _service = null!;

    [TestInitialize]
    public void Setup()
    {
        // 1. Mock af UserManager (Kræver en mock Store for at virke)
        var mockStore = new Mock<IUserStore<ApplicationUser>>();
        _mockUserManager = new Mock<UserManager<ApplicationUser>>(mockStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        // 2. Mock af DB Factory, JS Runtime og HttpContext
        _mockDbFactory = new Mock<IDbContextFactory<BankAppDbContext>>();
        _mockJsRuntime = new Mock<IJSRuntime>();
        _mockHttpAccessor = new Mock<IHttpContextAccessor>();

        // 3. Fake Configuration til JWT
        var inMemorySettings = new Dictionary<string, string?> {
            {"JWT:Key", "super_secret_test_key_that_is_long_enough_for_sha256!"},
            {"JWT:Issuer", "TestIssuer"},
            {"JWT:Audience", "TestAudience"}
        };
        _configuration = new ConfigurationBuilder().AddInMemoryCollection(inMemorySettings).Build();

        _service = new IdentityService(
            _mockUserManager.Object,
            _mockDbFactory.Object,
            _configuration,
            _mockJsRuntime.Object,
            _mockHttpAccessor.Object);
    }

    [TestMethod]
    public async Task Register_Success_AddsUserToRoleAndReturnsNull()
    {
        // Arrange
        var testUser = new ApplicationUser { UserName = "newuser" };
        _mockUserManager.Setup(x => x.CreateAsync(testUser, "Password123!"))
                        .ReturnsAsync(IdentityResult.Success);

        _mockUserManager.Setup(x => x.AddToRoleAsync(testUser, RoleType.Customer.ToString()))
                        .ReturnsAsync(IdentityResult.Success);

        // Act
        var errors = await _service.Register(testUser, "Password123!", RoleType.Customer);

        // Assert
        Assert.IsNull(errors, "Forventede ingen fejl ved succesfuld registrering.");
        _mockUserManager.Verify(x => x.AddToRoleAsync(testUser, "Customer"), Times.Once);
    }

    [TestMethod]
    public async Task Register_Failure_ReturnsListOfErrors()
    {
        // Arrange
        var testUser = new ApplicationUser { UserName = "newuser" };
        var failedResult = IdentityResult.Failed(new IdentityError { Description = "Password too weak" });

        _mockUserManager.Setup(x => x.CreateAsync(testUser, "weak"))
                        .ReturnsAsync(failedResult);

        // Act
        var errors = await _service.Register(testUser, "weak", RoleType.Customer);

        // Assert
        Assert.IsNotNull(errors);
        Assert.IsTrue(errors.Contains("Password too weak"));
        _mockUserManager.Verify(x => x.AddToRoleAsync(It.IsAny<ApplicationUser>(), It.IsAny<string>()), Times.Never);
    }

    [TestMethod]
    public async Task DeleteAccount_UserNotFound_ReturnsFalse()
    {
        // Arrange
        _mockUserManager.Setup(x => x.FindByIdAsync("user99")).ReturnsAsync((ApplicationUser)null!);

        // Act
        bool result = await _service.DeleteAccountAsync("user99");

        // Assert
        Assert.IsFalse(result);
    }
}
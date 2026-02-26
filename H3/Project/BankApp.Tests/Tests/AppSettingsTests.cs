using Microsoft.Extensions.Configuration;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace BankApp.Tests;

[TestClass]
public class AppSettingsTests
{
    private IConfiguration _config = null!;

    [TestInitialize]
    public void Setup()
    {
        // Grab config from our TestFactory
        _config = TestFactory.GetConfig();
    }

    [TestMethod, Priority(1)]
    public void Verify_Configuration_IsLoaded()
    {
        // Ensure the appsettings.json was actually found and read
        Assert.IsNotNull(_config, "TestFactory failed to load configuration.");
    }

    [TestMethod, Priority(1)]
    public void Verify_ConnectionString_Exists()
    {
        // Check if the database connection string is present and formatted
        var connectionString = _config.GetConnectionString("TestConnection");

        Assert.IsFalse(string.IsNullOrWhiteSpace(connectionString),
            "TestConnection is missing from appsettings.json.");

        Assert.IsTrue(connectionString!.Contains("Database="),
            "Connection string format looks invalid.");
    }

    [TestMethod, Priority(1)]
    public void Verify_JWT_Settings_Exists()
    {
        // Ensure security keys and token metadata are configured
        Assert.IsFalse(string.IsNullOrEmpty(_config["JWT:Key"]), "JWT Key is missing.");
        Assert.AreEqual("BankApp", _config["JWT:Issuer"]);
        Assert.AreEqual("BankApp", _config["JWT:Audience"]);
    }
}
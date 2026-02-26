using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Text;

namespace BankApp.Tests;

[TestClass]
public class AppSettingsTests
{
    private IConfiguration _config = null!;

    [TestInitialize]
    public void Setup()
    {
        // Use the factory to get config
        _config = TestFactory.GetConfig();
    }

    [TestMethod, Priority(1)]
    public void Verify_Configuration_Is_Loaded()
    {
        Assert.IsNotNull(_config, "TestFactory failed to load configuration.");
    }

    [TestMethod, Priority(1)]
    public void Verify_ConnectionString_Exists()
    {
        var connectionString = _config.GetConnectionString("TestConnection");

        Assert.IsFalse(string.IsNullOrWhiteSpace(connectionString),
            "TestConnection is missing from appsettings.json.");

        Assert.IsTrue(connectionString.Contains("Database="),
            "Connection string format looks invalid.");
    }

    [TestMethod, Priority(1)]
    public void Verify_JWT_Settings_Exist()
    {
        Assert.IsFalse(string.IsNullOrEmpty(_config["JWT:Key"]), "JWT Key is missing.");
        Assert.AreEqual("BankApp", _config["JWT:Issuer"]);
        Assert.AreEqual("BankApp", _config["JWT:Audience"]);
    }
}
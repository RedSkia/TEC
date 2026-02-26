using BankApp.Tests;
using Microsoft.Extensions.Configuration;

[TestClass]
public class AppSettingsTests
{
    private IConfiguration _config = null!;

    [TestInitialize]
    public void Setup() => _config = TestFactory.GetConfig();

    [TestMethod]
    public void Config_File_IsReadable()
        => Assert.IsNotNull(_config, "appsettings.json could not be loaded.");

    [TestMethod]
    public void Config_ConnectionString_IsPresent()
        => Assert.IsNotNull(_config.GetConnectionString("TestConnection"));

    [TestMethod]
    public void Config_JWT_Key_IsPresent()
        => Assert.IsNotNull(_config["JWT:Key"]);

    [TestMethod]
    public void Config_JWT_Metadata_IsCorrect()
    {
        Assert.AreEqual("BankApp", _config["JWT:Issuer"]);
        Assert.AreEqual("BankApp", _config["JWT:Audience"]);
    }
}
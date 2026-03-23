using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using SharedCore.Data;
using SharedCore.Services;

namespace SharedCore.Tests.UnitTests;

[TestClass]
public class FinanceServiceUnitTests
{
    private FinanceService _service = null!;

    [TestInitialize]
    public void Setup()
    {
        var mockDbFactory = new Mock<IDbContextFactory<BankAppDbContext>>();
        _service = new FinanceService(mockDbFactory.Object);
    }

    [TestMethod]
    public void GenRef_ShouldReturn12CharacterUppercaseString()
    {
        // Act
        string reference = _service.GenRef();

        // Assert
        Assert.IsNotNull(reference);
        Assert.AreEqual(12, reference.Length);
        Assert.AreEqual(reference.ToUpper(), reference, "Referencen skal være uppercase.");
    }

    [TestMethod]
    public void GenRef_ShouldGenerateUniqueValues()
    {
        // Act
        string ref1 = _service.GenRef();
        string ref2 = _service.GenRef();

        // Assert
        Assert.AreNotEqual(ref1, ref2, "To genererede referencer må ikke være ens.");
    }
}
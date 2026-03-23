using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using SharedCore.Data;
using SharedCore.Entities.Market;
using SharedCore.Services;

namespace SharedCore.Tests.UnitTests;

[TestClass]
public class StockMarketServiceUnitTests
{
    private Mock<IDbContextFactory<BankAppDbContext>> _mockDbFactory = null!;
    private StockMarketService _service = null!;

    [TestInitialize]
    public void Setup()
    {
        _mockDbFactory = new Mock<IDbContextFactory<BankAppDbContext>>();
        _service = new StockMarketService(_mockDbFactory.Object);
    }

    [TestMethod]
    public void GetGlobalState_Default_ReturnsNormal()
    {
        Assert.AreEqual(MarketState.Normal, _service.GetGlobalState());
    }

    [TestMethod]
    public void SetGlobalOverride_UpdatesGlobalState_AndClearsStockOverrides()
    {
        _service.SetStockOverride(1, MarketState.ForcedPump);
        _service.SetGlobalOverride(MarketState.ForcedCrash);

        Assert.AreEqual(MarketState.ForcedCrash, _service.GetGlobalState());
        Assert.AreEqual(MarketState.ForcedCrash, _service.GetStockState(1));
    }

    [TestMethod]
    public void SetStockOverride_BreaksGlobalState_AndSetsSpecificState()
    {
        _service.SetGlobalOverride(MarketState.ForcedPump);
        _service.SetStockOverride(99, MarketState.ForcedCrash);

        Assert.AreEqual(MarketState.Normal, _service.GetGlobalState());
        Assert.AreEqual(MarketState.ForcedCrash, _service.GetStockState(99));
    }

    [TestMethod]
    public void SetStockOverride_ToNormal_RemovesFromOverrides()
    {
        _service.SetStockOverride(5, MarketState.ForcedPump);
        _service.SetStockOverride(5, MarketState.Normal);

        Assert.AreEqual(MarketState.Normal, _service.GetStockState(5));
    }

    [TestMethod]
    public async Task ExecuteTrade_NullUserId_ReturnsFalseImmediately()
    {
        var result = await _service.ExecuteTrade(null, 1, 10m, true);

        Assert.IsFalse(result.Success);
        _mockDbFactory.Verify(f => f.CreateDbContextAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    [TestMethod]
    public async Task ExecuteTrade_ZeroQuantity_ReturnsFalseImmediately()
    {
        var result = await _service.ExecuteTrade("user1", 1, 0m, true);
        Assert.IsFalse(result.Success);
    }

    [TestMethod]
    public async Task ExecuteTrade_NegativeQuantity_ReturnsFalseImmediately()
    {
        var result = await _service.ExecuteTrade("user1", 1, -5m, true);
        Assert.IsFalse(result.Success);
    }
}
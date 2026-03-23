using System.Reflection;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using SharedCore.Data;
using SharedCore.Entities.Auth; // Vigtigt: Til ApplicationUser
using SharedCore.Entities.Banking;
using SharedCore.Entities.Market;
using SharedCore.Services;

namespace SharedCore.Tests.IntegrationTests;

[TestClass]
public class StockMarketServiceIntegrationTests
{
    private SqliteConnection _connection = null!;
    private DbContextOptions<BankAppDbContext> _options = null!;
    private Mock<IDbContextFactory<BankAppDbContext>> _mockFactory = null!;
    private StockMarketService _service = null!;

    [TestInitialize]
    public void Setup()
    {
        string uniqueDbName = Guid.NewGuid().ToString();
        _connection = new SqliteConnection($"DataSource=file:{uniqueDbName}?mode=memory&cache=shared");
        _connection.Open();

        _options = new DbContextOptionsBuilder<BankAppDbContext>()
            .UseSqlite(_connection)
            .Options;

        using (var context = new BankAppDbContext(_options))
        {
            context.Database.EnsureDeleted();
            // EnsureCreated() kører nu din HasData() og seeder CurrencyTypes og Stocks!
            context.Database.EnsureCreated();
        }

        _mockFactory = new Mock<IDbContextFactory<BankAppDbContext>>();
        _mockFactory.Setup(f => f.CreateDbContextAsync(It.IsAny<CancellationToken>()))
                    .ReturnsAsync(() => new BankAppDbContext(_options));

        _service = new StockMarketService(_mockFactory.Object);
        _service.SetGlobalOverride(MarketState.Normal);
    }

    [TestCleanup]
    public void Cleanup()
    {
        _connection.Close();
    }

    private async Task SeedDatabaseAsync(decimal initialStockPrice = 100m)
    {
        using var db = new BankAppDbContext(_options);

        // 1. Sørg for at brugeren findes
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == "user1");
        if (user == null)
        {
            user = new ApplicationUser { Id = "user1", UserName = "testuser", Email = "test@test.com" };
            db.Users.Add(user);
            await db.SaveChangesAsync();
        }

        // 2. HENT den bankkonto, der hører til brugeren (da EF Core højst sandsynligt 
        // allerede har auto-oprettet den med 0 i saldo). Tving den til at have 1000m!
        var account = await db.BankAccounts.FirstOrDefaultAsync(a => a.UserId == "user1");
        if (account == null)
        {
            account = new BankAccount { UserId = "user1", Balance = 1000m, CurrencyTypeId = 1 };
            db.BankAccounts.Add(account);
        }
        else
        {
            // Hvis den auto-blev oprettet, overskriver vi bare saldoen!
            account.Balance = 1000m;
            account.CurrencyTypeId = 1;
        }
        await db.SaveChangesAsync();

        // 3. Opdater startprisen på aktie 1 (VOID-TECH SYSTEMS), som allerede findes
        var stock = await db.Stocks.FindAsync(1);
        if (stock != null)
        {
            stock.CurrentPrice = initialStockPrice;
            await db.SaveChangesAsync();
        }
    }

    // --- TEST AF KØB (BUY) ---

    [TestMethod]
    public async Task ExecuteTrade_Buy_SufficientFunds_Success()
    {
        await SeedDatabaseAsync();
        var result = await _service.ExecuteTrade("user1", 1, 5m, isBuy: true);

        Assert.IsTrue(result.Success, result.Message);

        using var db = new BankAppDbContext(_options);
        var account = await db.BankAccounts.FirstAsync(a => a.UserId == "user1");
        var investment = await db.Investments.FirstAsync();
        var transaction = await db.Transactions.FirstAsync();

        Assert.AreEqual(500m, account.Balance);
        Assert.AreEqual(5m, investment.Quantity);
        Assert.AreEqual(TransactionType.Withdraw, transaction.Type);
    }

    [TestMethod]
    public async Task ExecuteTrade_Buy_ExistingInvestment_AddsToQuantity()
    {
        await SeedDatabaseAsync();
        using (var db = new BankAppDbContext(_options))
        {
            var account = await db.BankAccounts.FirstAsync(a => a.UserId == "user1");
            db.Investments.Add(new Investment { BankAccountId = account.Id, StockId = 1, Quantity = 2m });
            await db.SaveChangesAsync();
        }

        var result = await _service.ExecuteTrade("user1", 1, 3m, isBuy: true);

        Assert.IsTrue(result.Success, result.Message);
        using var dbVerify = new BankAppDbContext(_options);
        var investment = await dbVerify.Investments.FirstAsync();
        Assert.AreEqual(5m, investment.Quantity);
    }

    [TestMethod]
    public async Task ExecuteTrade_Buy_InsufficientFunds_ReturnsFalse()
    {
        await SeedDatabaseAsync();
        var result = await _service.ExecuteTrade("user1", 1, 20m, isBuy: true);

        Assert.IsFalse(result.Success);
        Assert.AreEqual("Insufficient capital for market entry.", result.Message);

        using var db = new BankAppDbContext(_options);
        Assert.AreEqual(1000m, (await db.BankAccounts.FirstAsync(a => a.UserId == "user1")).Balance);
    }

    // --- TEST AF SALG (SELL) ---

    [TestMethod]
    public async Task ExecuteTrade_Sell_PartialLiquidation_Success()
    {
        await SeedDatabaseAsync();
        using (var db = new BankAppDbContext(_options))
        {
            var account = await db.BankAccounts.FirstAsync(a => a.UserId == "user1");
            db.Investments.Add(new Investment { BankAccountId = account.Id, StockId = 1, Quantity = 10m });
            await db.SaveChangesAsync();
        }

        var result = await _service.ExecuteTrade("user1", 1, 4m, isBuy: false);

        Assert.IsTrue(result.Success, result.Message);
        using var dbVerify = new BankAppDbContext(_options);
        Assert.AreEqual(1400m, (await dbVerify.BankAccounts.FirstAsync(a => a.UserId == "user1")).Balance);
        Assert.AreEqual(6m, (await dbVerify.Investments.FirstAsync()).Quantity);
    }

    [TestMethod]
    public async Task ExecuteTrade_Sell_FullLiquidation_DeletesInvestmentRecord()
    {
        await SeedDatabaseAsync();
        using (var db = new BankAppDbContext(_options))
        {
            var account = await db.BankAccounts.FirstAsync(a => a.UserId == "user1");
            db.Investments.Add(new Investment { BankAccountId = account.Id, StockId = 1, Quantity = 5m });
            await db.SaveChangesAsync();
        }

        var result = await _service.ExecuteTrade("user1", 1, 5m, isBuy: false);

        Assert.IsTrue(result.Success, result.Message);
        using var dbVerify = new BankAppDbContext(_options);
        Assert.IsFalse(await dbVerify.Investments.AnyAsync());
    }

    [TestMethod]
    public async Task ExecuteTrade_Sell_InsufficientVolume_ReturnsFalse()
    {
        await SeedDatabaseAsync();
        using (var db = new BankAppDbContext(_options))
        {
            var account = await db.BankAccounts.FirstAsync(a => a.UserId == "user1");
            db.Investments.Add(new Investment { BankAccountId = account.Id, StockId = 1, Quantity = 2m });
            await db.SaveChangesAsync();
        }

        var result = await _service.ExecuteTrade("user1", 1, 5m, isBuy: false);

        Assert.IsFalse(result.Success);
        Assert.AreEqual("Insufficient asset volume for liquidation.", result.Message);
    }

    // --- TEST AF PRIVATE METODE (UpdateMarketPrices) VIA REFLECTION ---

    [TestMethod]
    public async Task UpdateMarketPrices_ClampsPennyStockFloor()
    {
        await SeedDatabaseAsync(0.001m);

        var method = typeof(StockMarketService).GetMethod("UpdateMarketPrices", BindingFlags.NonPublic | BindingFlags.Instance);
        await (Task)method!.Invoke(_service, null)!;

        using var db = new BankAppDbContext(_options);
        var stock = await db.Stocks.FirstAsync(s => s.Id == 1);
        Assert.AreEqual(0.01m, stock.CurrentPrice);
    }

    [TestMethod]
    public async Task UpdateMarketPrices_LogsStockHistory()
    {
        await SeedDatabaseAsync(100m);
        var method = typeof(StockMarketService).GetMethod("UpdateMarketPrices", BindingFlags.NonPublic | BindingFlags.Instance);
        await (Task)method!.Invoke(_service, null)!;

        using var db = new BankAppDbContext(_options);
        var history = await db.StockHistory.ToListAsync();

        // Vi forventer nu 10, fordi din DbContext indeholder 10 aktier fra starten.
        Assert.AreEqual(10, history.Count);
    }
}
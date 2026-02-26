using BankApp.Data;
using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Lending;
using BankApp.Data.Entities.Market;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace BankApp.Tests;

[TestClass]
public class DatabaseRelationsTests
{
    private BankAppDbContext _context = null!;
    private Microsoft.Extensions.Configuration.IConfiguration _config = null!;

    [TestInitialize]
    public void Setup()
    {
        _config = TestFactory.GetConfig();
        _context = TestFactory.CreateDbContext(_config);
        _context.Database.EnsureDeleted();
        _context.Database.EnsureCreated();
    }

    private BankAppDbContext GetFreshContext() => TestFactory.CreateDbContext(_config);

    [TestMethod]
    public async Task Relation_User_To_Address_Works()
    {
        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), UserName = "u1@test.dk", Email = "u1@test.dk" };
        var address = new Address { Street = "Main St", City = "Roskilde", ZipCode = "4000", User = user };

        _context.Addresses.Add(address);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.Users.FirstOrDefaultAsync(u => u.Email == "u1@test.dk");
        Assert.IsNotNull(fetched?.Address);
    }

    [TestMethod]
    public async Task Relation_User_To_BankAccounts_Works()
    {
        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), UserName = "u2@test.dk", Email = "u2@test.dk" };
        var account = new BankAccount { AccountNumber = "ACC-01", User = user };

        _context.BankAccounts.Add(account);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.Users.FirstOrDefaultAsync(u => u.Email == "u2@test.dk");
        Assert.AreEqual(1, fetched?.BankAccounts.Count);
    }

    [TestMethod]
    public async Task Relation_BankAccount_To_Transactions_Works()
    {
        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), UserName = "u3@test.dk", Email = "u3@test.dk" };
        var account = new BankAccount { AccountNumber = "TRX-ACC", User = user };
        account.Transactions.Add(new Transaction { Amount = 100, Type = TransactionType.Deposit });

        _context.BankAccounts.Add(account); // Add the Account directly to track children
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.BankAccounts.FirstOrDefaultAsync(a => a.AccountNumber == "TRX-ACC");
        Assert.AreEqual(1, fetched?.Transactions.Count);
    }

    [TestMethod]
    public async Task Relation_BankAccount_To_Cards_Works()
    {
        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), UserName = "u4@test.dk", Email = "u4@test.dk" };
        var account = new BankAccount { AccountNumber = "CARD-ACC", User = user };
        account.Cards.Add(new Card { CardNumber = "1234", Cvc = "123", ExpiryDate = "10/25" });

        _context.BankAccounts.Add(account);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.BankAccounts.FirstOrDefaultAsync(a => a.AccountNumber == "CARD-ACC");
        Assert.AreEqual(1, fetched?.Cards.Count);
    }

    [TestMethod]
    public async Task Relation_BankAccount_To_LoanRequests_Works()
    {
        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), UserName = "u5@test.dk", Email = "u5@test.dk" };
        var account = new BankAccount { AccountNumber = "LOAN-ACC", User = user };
        account.LoanRequests.Add(new LoanRequest { Amount = 5000, MessageFromCustomer = "Test" });

        _context.BankAccounts.Add(account);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        // LoanRequests doesn't have AutoInclude in your context, adding it here
        var fetched = await db.BankAccounts.Include(a => a.LoanRequests).FirstOrDefaultAsync(a => a.AccountNumber == "LOAN-ACC");
        Assert.AreEqual(1, fetched?.LoanRequests.Count);
    }

    [TestMethod]
    public async Task Relation_BankAccount_To_Investments_Works()
    {
        var stock = new Stock { Ticker = "AAPL", Name = "Apple", CurrentPrice = 150 };
        _context.Stocks.Add(stock);
        await _context.SaveChangesAsync();

        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), UserName = "u6@test.dk", Email = "u6@test.dk" };
        var account = new BankAccount { AccountNumber = "INV-ACC", User = user };
        account.Investments.Add(new Investment { StockId = stock.Id, Quantity = 10 });

        _context.BankAccounts.Add(account);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.BankAccounts.FirstOrDefaultAsync(a => a.AccountNumber == "INV-ACC");
        Assert.AreEqual(1, fetched?.Investments.Count);
    }

    [TestMethod]
    public async Task Relation_Investment_To_Stock_Works()
    {
        var stock = new Stock { Ticker = "MSFT", Name = "Microsoft", CurrentPrice = 300 };
        _context.Stocks.Add(stock);
        await _context.SaveChangesAsync();

        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), UserName = "u7@test.dk", Email = "u7@test.dk" };
        var account = new BankAccount { AccountNumber = "STOCK-ACC", User = user };
        account.Investments.Add(new Investment { StockId = stock.Id, Quantity = 5 });

        _context.BankAccounts.Add(account);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.BankAccounts.FirstOrDefaultAsync(a => a.AccountNumber == "STOCK-ACC");
        var investment = fetched?.Investments.FirstOrDefault();

        Assert.IsNotNull(investment?.Stock);
        Assert.AreEqual("MSFT", investment.Stock.Ticker);
    }

    [TestCleanup]
    public void Cleanup() => _context?.Dispose();
}
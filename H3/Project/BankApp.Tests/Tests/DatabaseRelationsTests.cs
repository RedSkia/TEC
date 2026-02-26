using BankApp.Data;
using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Lending;
using BankApp.Data.Entities.Market;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.Extensions.Configuration;

namespace BankApp.Tests;

[TestClass]
public class DatabaseRelationsTests
{
    private BankAppDbContext _context = null!;
    private IConfiguration _config = null!;

    [TestInitialize]
    public void Setup()
    {
        _config = TestFactory.GetConfig();
        _context = TestFactory.CreateDbContext(_config);
        _context.Database.EnsureDeleted();
        _context.Database.EnsureCreated();
    }

    private BankAppDbContext GetFreshContext() => TestFactory.CreateDbContext(_config);

    // -----------------------------------------------------------
    // 1. AUTO-INCLUDE VERIFICATION (The "Golden Path")
    // -----------------------------------------------------------

    [TestMethod]
    public async Task Should_AutoInclude_Address_When_Fetching_User()
    {
        var uid = Guid.NewGuid().ToString();
        var user = new ApplicationUser { Id = uid, UserName = "u1", Email = "u1@test.dk" };
        _context.Addresses.Add(new Address { Street = "Main St", City = "Roskilde", ZipCode = "4000", User = user });
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.Users.FirstOrDefaultAsync(u => u.Id == uid);

        Assert.IsNotNull(fetched?.Address);
        Assert.AreEqual("Roskilde", fetched.Address.City);
    }

    [TestMethod]
    public async Task Should_AutoInclude_BankAccounts_When_Fetching_User()
    {
        var uid = Guid.NewGuid().ToString();
        var user = new ApplicationUser { Id = uid, UserName = "u2" };
        _context.BankAccounts.Add(new BankAccount { AccountNumber = "ACC-01", User = user });
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.Users.FirstOrDefaultAsync(u => u.Id == uid);
        Assert.AreEqual(1, fetched?.BankAccounts.Count);
    }

    [TestMethod]
    public async Task Should_AutoInclude_Transactions_When_Fetching_BankAccount()
    {
        var uid = Guid.NewGuid().ToString();
        var user = new ApplicationUser { Id = uid, UserName = "u3" };
        var account = new BankAccount { AccountNumber = "TRX-ACC", User = user };
        account.Transactions.Add(new Transaction { Amount = 100, Type = TransactionType.Deposit });

        _context.BankAccounts.Add(account);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.BankAccounts.FirstOrDefaultAsync(a => a.AccountNumber == "TRX-ACC");
        Assert.AreEqual(1, fetched?.Transactions.Count);
    }

    [TestMethod]
    public async Task Should_AutoInclude_Stock_Inside_Investment_Deep_Load()
    {
        var stock = new Stock { Ticker = "MSFT", Name = "Microsoft", CurrentPrice = 300 };
        _context.Stocks.Add(stock);
        await _context.SaveChangesAsync();

        var uid = Guid.NewGuid().ToString();
        var user = new ApplicationUser { Id = uid, UserName = "u4" };
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

    [TestMethod]
    public async Task Should_AutoInclude_LoginActivities_When_Fetching_User()
    {
        var uid = Guid.NewGuid().ToString();
        var user = new ApplicationUser { Id = uid, UserName = "u5" };
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        _context.LoginActivities.Add(new LoginActivity { UserId = uid, IpAddress = "127.0.0.1", Status = LoginStatus.Success });
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.Users.FirstOrDefaultAsync(u => u.Id == uid);
        Assert.AreEqual(1, fetched?.LoginActivities.Count);
    }

    // -----------------------------------------------------------
    // 2. SPECIAL HANDLING (Cycle Breakers)
    // -----------------------------------------------------------

    [TestMethod]
    public async Task Should_Require_Manual_Include_For_AssignedOfficer_Due_To_Type_Cycle()
    {
        var offId = Guid.NewGuid().ToString();
        var officer = new ApplicationUser { Id = offId, UserName = "off", FullName = "Officer Bob" };
        _context.Users.Add(officer);
        await _context.SaveChangesAsync();

        var uid = Guid.NewGuid().ToString();
        var customer = new ApplicationUser { Id = uid, UserName = "cust" };
        var account = new BankAccount { AccountNumber = "LOAN-ACC", User = customer };
        account.LoanRequests.Add(new LoanRequest { Amount = 5000, MessageFromCustomer = "Test", AssignedOfficerId = offId });

        _context.BankAccounts.Add(account);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        // Since AutoInclude is disabled for AssignedOfficer to prevent crashes, we verify manual include works
        var fetched = await db.LoanRequests.Include(l => l.AssignedOfficer).FirstAsync();
        Assert.AreEqual("Officer Bob", fetched.AssignedOfficer?.FullName);
    }

    // -----------------------------------------------------------
    // 3. CASCADE DELETE VERIFICATION
    // -----------------------------------------------------------

    [TestMethod]
    public async Task Should_Cascade_Delete_Address_And_Accounts_When_User_Is_Deleted()
    {
        var uid = Guid.NewGuid().ToString();
        var user = new ApplicationUser { Id = uid, UserName = "del" };
        _context.Addresses.Add(new Address { Street = "X", City = "Y", ZipCode = "0000", User = user });
        _context.BankAccounts.Add(new BankAccount { AccountNumber = "DEL-ACC", User = user });
        await _context.SaveChangesAsync();

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();

        Assert.IsFalse(await _context.Addresses.AnyAsync(a => a.UserId == uid));
        Assert.IsFalse(await _context.BankAccounts.AnyAsync(b => b.UserId == uid));
    }

    [TestMethod]
    public async Task Should_Cascade_Delete_Transactions_And_Cards_When_Account_Is_Deleted()
    {
        var uid = Guid.NewGuid().ToString();
        var user = new ApplicationUser { Id = uid, UserName = "owner" };
        var acc = new BankAccount { AccountNumber = "OWNED-ACC", User = user };
        _context.BankAccounts.Add(acc);
        await _context.SaveChangesAsync();

        int accId = acc.Id;
        _context.Transactions.Add(new Transaction { BankAccountId = accId, Amount = 10 });
        _context.Cards.Add(new Card { BankAccountId = accId, CardNumber = "123", Cvc = "123", ExpiryDate = "10/25" });
        await _context.SaveChangesAsync();

        _context.BankAccounts.Remove(acc);
        await _context.SaveChangesAsync();

        Assert.IsFalse(await _context.Transactions.AnyAsync(t => t.BankAccountId == accId));
        Assert.IsFalse(await _context.Cards.AnyAsync(c => c.BankAccountId == accId));
    }

    [TestCleanup]
    public void Cleanup() => _context?.Dispose();
}
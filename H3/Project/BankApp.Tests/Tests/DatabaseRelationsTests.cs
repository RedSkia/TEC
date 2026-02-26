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

    #region 1. AUTH & USER DEEP DIVE

    [TestMethod]
    public async Task User_Complete_Lifecycle_With_Identity_Properties()
    {
        var user = new ApplicationUser
        {
            UserName = "fullstack@bank.dk",
            Email = "fullstack@bank.dk",
            FullName = "Test User",
            PhoneNumber = "12345678",
            TwoFactorEnabled = true
        };
        user.Address = new Address { Street = "Code Lane 1", City = "Roskilde", ZipCode = "4000" };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var fetched = await db.Users.Include(u => u.Address).FirstOrDefaultAsync(u => u.Email == "fullstack@bank.dk");

        Assert.IsNotNull(fetched);
        Assert.AreEqual("Test User", fetched.FullName);
        Assert.IsTrue(fetched.TwoFactorEnabled);
        Assert.AreEqual("Code Lane 1", fetched.Address.Street);
    }

    [TestMethod]
    public async Task LoginActivity_Audit_Trail_Persistence()
    {
        var user = new ApplicationUser { UserName = "security@bank.dk", Email = "security@bank.dk" };
        var activities = new List<LoginActivity>
        {
            new() { User = user, IpAddress = "1.1.1.1", Status = LoginStatus.Success, UserAgent = "Chrome" },
            new() { User = user, IpAddress = "1.1.1.2", Status = LoginStatus.InvalidPassword, UserAgent = "Firefox" },
            new() { User = user, IpAddress = "1.1.1.3", Status = LoginStatus.AccountLocked, UserAgent = "Edge" }
        };

        _context.LoginActivities.AddRange(activities);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var dbUser = await db.Users.Include(u => u.LoginActivities).FirstOrDefaultAsync(u => u.Email == "security@bank.dk");
        Assert.AreEqual(3, dbUser!.LoginActivities.Count);
        Assert.IsTrue(dbUser.LoginActivities.Any(a => a.Status == LoginStatus.AccountLocked));
    }

    #endregion

    #region 2. BANKING & CARD COMPLEXITY

    [TestMethod]
    public async Task BankAccount_With_Mixed_Transactions_And_Cards()
    {
        var user = new ApplicationUser { UserName = "rich@bank.dk", Email = "rich@bank.dk" };
        var account = new BankAccount { AccountNumber = "GOLD-001", Balance = 99999.99m, User = user };

        // Add Transactions
        account.Transactions.Add(new Transaction { Amount = 100, Type = TransactionType.Deposit, Note = "Gift" });
        account.Transactions.Add(new Transaction { Amount = -50, Type = TransactionType.Withdraw, Note = "Dinner" });

        // Add Multiple Cards
        account.Cards.Add(new Card { CardNumber = "1111222233334444", Cvc = "111", ExpiryDate = "01/25", IsBlocked = false });
        account.Cards.Add(new Card { CardNumber = "5555666677778888", Cvc = "222", ExpiryDate = "02/26", IsBlocked = true });

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var dbAcc = await db.BankAccounts.Include(a => a.Transactions).Include(a => a.Cards)
                            .FirstOrDefaultAsync(a => a.AccountNumber == "GOLD-001");

        Assert.AreEqual(2, dbAcc!.Transactions.Count);
        Assert.AreEqual(2, dbAcc.Cards.Count);
        Assert.IsTrue(dbAcc.Cards.First(c => c.CardNumber.StartsWith("5555")).IsBlocked);
    }

    #endregion

    #region 3. LENDING & ASSIGNMENT RELATIONS

    [TestMethod]
    public async Task LoanRequest_Full_Mapping_With_Officer_Assignment()
    {
        var client = new ApplicationUser { UserName = "borrower@bank.dk", Email = "borrower@bank.dk" };
        var officer = new ApplicationUser { UserName = "officer@bank.dk", Email = "officer@bank.dk" };
        var account = new BankAccount { User = client, AccountNumber = "ACC-LOAN" };

        var loan = new LoanRequest
        {
            BankAccount = account,
            Amount = 250000,
            InterestRate = 4.25m,
            Status = LoanStatus.UnderReview,
            MessageFromCustomer = "Business Expansion",
            ResponseFromOfficer = "Awaiting financial statements",
            AssignedOfficer = officer
        };

        _context.Users.AddRange(client, officer);
        _context.LoanRequests.Add(loan);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var dbLoan = await db.LoanRequests
            .Include(l => l.BankAccount).ThenInclude(a => a.User)
            .Include(l => l.AssignedOfficer)
            .FirstOrDefaultAsync();

        Assert.IsNotNull(dbLoan);
        Assert.AreEqual("borrower@bank.dk", dbLoan.BankAccount.User.Email);
        Assert.AreEqual("officer@bank.dk", dbLoan.AssignedOfficer!.Email);
        Assert.AreEqual(4.25m, dbLoan.InterestRate);
    }

    #endregion

    #region 4. MARKET, STOCKS & INVESTMENTS

    [TestMethod]
    public async Task Market_Investment_Stock_Many_To_Many_Simulation()
    {
        var user = new ApplicationUser { UserName = "trader@bank.dk", Email = "trader@bank.dk" };
        var account = new BankAccount { User = user, AccountNumber = "PORTFOLIO-1" };

        var stockA = new Stock { Ticker = "NVDA", Name = "Nvidia", CurrentPrice = 900m };
        var stockB = new Stock { Ticker = "TSLA", Name = "Tesla", CurrentPrice = 170m };

        // Bridge table data
        account.Investments.Add(new Investment { Stock = stockA, Quantity = 5.5m });
        account.Investments.Add(new Investment { Stock = stockB, Quantity = 20.0m });

        _context.Users.Add(user);
        _context.Stocks.AddRange(stockA, stockB);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var dbAcc = await db.BankAccounts
            .Include(a => a.Investments).ThenInclude(i => i.Stock)
            .FirstOrDefaultAsync(a => a.AccountNumber == "PORTFOLIO-1");

        Assert.AreEqual(2, dbAcc!.Investments.Count);
        var nvda = dbAcc.Investments.First(i => i.Stock.Ticker == "NVDA");
        Assert.AreEqual(5.5m, nvda.Quantity);
    }

    #endregion

    #region 5. DATABASE CONSTRAINTS & CASCADES

    [TestMethod]
    public async Task Cascade_Delete_Hierarchy_Check()
    {
        var user = new ApplicationUser { UserName = "disposable@bank.dk", Email = "disposable@bank.dk" };
        var account = new BankAccount { User = user };
        account.Transactions.Add(new Transaction { Amount = 100, Type = TransactionType.Deposit });
        account.Cards.Add(new Card { CardNumber = "0000000000000000", Cvc = "000", ExpiryDate = "01/01" });

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        // ACT: Blow away the user
        _context.Users.Remove(user);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        Assert.IsFalse(await db.BankAccounts.AnyAsync(), "BankAccount survived User deletion.");
        Assert.IsFalse(await db.Transactions.AnyAsync(), "Transactions survived Account deletion.");
        Assert.IsFalse(await db.Cards.AnyAsync(), "Cards survived Account deletion.");
    }

    [TestMethod]
    public async Task Stock_Update_Reflects_In_Investment_Navigation()
    {
        var stock = new Stock { Ticker = "GOOGL", Name = "Google", CurrentPrice = 150m };
        var user = new ApplicationUser { UserName = "holder@bank.dk", Email = "holder@bank.dk" };
        var account = new BankAccount { User = user };
        var invest = new Investment { Stock = stock, BankAccount = account, Quantity = 1 };

        _context.Add(invest);
        await _context.SaveChangesAsync();

        // ACT: Update the price of the stock globally
        stock.CurrentPrice = 165.50m;
        _context.Update(stock);
        await _context.SaveChangesAsync();

        using var db = GetFreshContext();
        var dbInvest = await db.Investments.Include(i => i.Stock).FirstAsync();
        Assert.AreEqual(165.50m, dbInvest.Stock.CurrentPrice);
    }

    #endregion

    [TestCleanup]
    public void Cleanup() => _context?.Dispose();
}
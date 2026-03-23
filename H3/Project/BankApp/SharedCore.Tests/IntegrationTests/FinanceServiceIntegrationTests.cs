using System.Reflection;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using SharedCore.Data;
using SharedCore.Entities.Auth;
using SharedCore.Entities.Banking;
using SharedCore.Entities.Lending;
using SharedCore.Services;

namespace SharedCore.Tests.IntegrationTests;

[TestClass]
public class FinanceServiceIntegrationTests
{
    private SqliteConnection _connection = null!;
    private DbContextOptions<BankAppDbContext> _options = null!;
    private Mock<IDbContextFactory<BankAppDbContext>> _mockFactory = null!;
    private FinanceService _service = null!;

    [TestInitialize]
    public void Setup()
    {
        // 100% isoleret database pr. test
        string uniqueDbName = Guid.NewGuid().ToString();
        _connection = new SqliteConnection($"DataSource=file:{uniqueDbName}?mode=memory&cache=shared");
        _connection.Open();

        _options = new DbContextOptionsBuilder<BankAppDbContext>()
            .UseSqlite(_connection)
            .Options;

        using (var context = new BankAppDbContext(_options))
        {
            context.Database.EnsureCreated(); // Sætter skema, valutaer og aktier op via HasData
        }

        _mockFactory = new Mock<IDbContextFactory<BankAppDbContext>>();
        _mockFactory.Setup(f => f.CreateDbContextAsync(It.IsAny<CancellationToken>()))
                    .ReturnsAsync(() => new BankAppDbContext(_options));

        _service = new FinanceService(_mockFactory.Object);
    }

    [TestCleanup]
    public void Cleanup()
    {
        _connection.Close();
    }

    private async Task SeedDatabaseAsync()
    {
        using var db = new BankAppDbContext(_options);

        // Opret Sender
        if (!await db.Users.AnyAsync(u => u.Id == "sender-id"))
            db.Users.Add(new ApplicationUser { Id = "sender-id", UserName = "sender", Email = "s@test.com" });

        // Opret Receiver
        if (!await db.Users.AnyAsync(u => u.Id == "receiver-id"))
            db.Users.Add(new ApplicationUser { Id = "receiver-id", UserName = "receiver", Email = "r@test.com" });

        await db.SaveChangesAsync();

        // Opsæt Sender Konto (Currency 1 = EUR)
        var senderAcc = await db.BankAccounts.FirstOrDefaultAsync(a => a.UserId == "sender-id");
        if (senderAcc == null) db.BankAccounts.Add(new BankAccount { UserId = "sender-id", Balance = 2000m, CurrencyTypeId = 1 });
        else { senderAcc.Balance = 2000m; senderAcc.CurrencyTypeId = 1; }

        // Opsæt Receiver Konto (Currency 1 = EUR)
        var receiverAcc = await db.BankAccounts.FirstOrDefaultAsync(a => a.UserId == "receiver-id");
        if (receiverAcc == null) db.BankAccounts.Add(new BankAccount { UserId = "receiver-id", Balance = 500m, CurrencyTypeId = 1 });
        else { receiverAcc.Balance = 500m; receiverAcc.CurrencyTypeId = 1; }

        await db.SaveChangesAsync();
    }

    // --- TEST AF TRANSFERS ---

    [TestMethod]
    public async Task ExecuteTransfer_ValidAccounts_TransfersFundsAndLogs()
    {
        await SeedDatabaseAsync();

        // Act: Sender 500 fra Sender (2000) til Receiver (500)
        var result = await _service.ExecuteTransfer("sender-id", "receiver-id", 500m);

        // Assert
        Assert.IsTrue(result.Success, result.Message);

        using var db = new BankAppDbContext(_options);
        var sender = await db.BankAccounts.FirstAsync(a => a.UserId == "sender-id");
        var receiver = await db.BankAccounts.FirstAsync(a => a.UserId == "receiver-id");

        Assert.AreEqual(1500m, sender.Balance);
        Assert.AreEqual(1000m, receiver.Balance);

        // Tjek transaktionslog
        var transactions = await db.Transactions.ToListAsync();
        Assert.IsTrue(transactions.Any(t => t.BankAccountId == sender.Id && t.Amount == -500m && t.Type == TransactionType.Transfer));
        Assert.IsTrue(transactions.Any(t => t.BankAccountId == receiver.Id && t.Amount == 500m && t.Type == TransactionType.Transfer));
    }

    [TestMethod]
    public async Task ExecuteTransfer_InsufficientFunds_ReturnsFalse()
    {
        await SeedDatabaseAsync();

        // Act: Prøver at sende 5000 (Sender har kun 2000)
        var result = await _service.ExecuteTransfer("sender-id", "receiver-id", 5000m);

        // Assert
        Assert.IsFalse(result.Success);

        using var db = new BankAppDbContext(_options);
        var sender = await db.BankAccounts.FirstAsync(a => a.UserId == "sender-id");
        Assert.AreEqual(2000m, sender.Balance); // Saldo er uberørt
    }

    // --- TEST AF ADMIN OVERRIDE ---

    [TestMethod]
    public async Task AdjustUserBalance_ValidUser_UpdatesBalance()
    {
        await SeedDatabaseAsync();

        var result = await _service.AdjustUserBalance("sender-id", 250m, "Correction");

        Assert.IsTrue(result);
        using var db = new BankAppDbContext(_options);
        var acc = await db.BankAccounts.FirstAsync(a => a.UserId == "sender-id");
        Assert.AreEqual(2250m, acc.Balance);
    }

    // --- TEST AF VALUTA ---

    [TestMethod]
    public async Task UpdateAccountCurrency_CalculatesNewBalanceCorrectly()
    {
        await SeedDatabaseAsync();
        // Starter med 2000 EUR (Rate 1.0). Skifter til USD (Rate 1.08 ifølge HasData).
        // Forventet formel: (2000 / 1.0) * 1.08 = 2160.

        var result = await _service.UpdateAccountCurrency("sender-id", 2); // 2 = USD

        Assert.IsTrue(result);

        using var db = new BankAppDbContext(_options);
        var acc = await db.BankAccounts.FirstAsync(a => a.UserId == "sender-id");

        Assert.AreEqual(2, acc.CurrencyTypeId);
        Assert.AreEqual(2160m, acc.Balance);
    }

    [TestMethod]
    public async Task UpdateAccountCurrency_SameCurrency_ReturnsFalse()
    {
        await SeedDatabaseAsync();

        var result = await _service.UpdateAccountCurrency("sender-id", 1); // Prøver at skifte til EUR (allerede EUR)

        Assert.IsFalse(result);
    }

    // --- TEST AF LÅN ---

    [TestMethod]
    public async Task UpdateLoanStatusAsync_ApproveLoan_AddsBalanceAndLogs()
    {
        await SeedDatabaseAsync();
        int loanId;

        using (var dbSetup = new BankAppDbContext(_options))
        {
            // FIKS: Vi opretter officeren i databasen, så Foreign Key relatonen ikke fejler!
            if (!await dbSetup.Users.AnyAsync(u => u.Id == "officer-1"))
            {
                dbSetup.Users.Add(new ApplicationUser { Id = "officer-1", UserName = "officer", Email = "officer@test.com" });
            }

            var acc = await dbSetup.BankAccounts.FirstAsync(a => a.UserId == "sender-id");
            var loan = new LoanRequest { BankAccountId = acc.Id, Amount = 1000m, CurrencyTypeId = 1, Status = LoanStatus.Open, RequestReference = "LOAN_REQ_001" };

            dbSetup.LoanRequests.Add(loan);
            await dbSetup.SaveChangesAsync();
            loanId = loan.Id;
        }

        // Act
        var result = await _service.UpdateLoanStatusAsync(loanId, LoanStatus.Approved, "officer-1", "Looks good");

        // Assert
        Assert.IsTrue(result, "Lånet burde blive godkendt uden databasefejl.");

        using var db = new BankAppDbContext(_options);
        var accVerify = await db.BankAccounts.FirstAsync(a => a.UserId == "sender-id");
        var loanVerify = await db.LoanRequests.FirstAsync(l => l.Id == loanId);

        Assert.AreEqual(3000m, accVerify.Balance); // 2000 + 1000
        Assert.AreEqual(LoanStatus.Approved, loanVerify.Status);
        Assert.AreEqual("officer-1", loanVerify.AssignedOfficerId);
    }

    [TestMethod]
    public async Task RepayLoanAsync_ApprovedLoan_DeductsBalanceAndClosesLoan()
    {
        await SeedDatabaseAsync();
        int loanId;

        using (var dbSetup = new BankAppDbContext(_options))
        {
            var acc = await dbSetup.BankAccounts.FirstAsync(a => a.UserId == "sender-id");
            // Fiks: RequestReference er nu længere end 8 tegn ("LOAN_REQ_002")
            var loan = new LoanRequest { BankAccountId = acc.Id, Amount = 500m, CurrencyTypeId = 1, Status = LoanStatus.Approved, RequestReference = "LOAN_REQ_002" };
            dbSetup.LoanRequests.Add(loan);
            await dbSetup.SaveChangesAsync();
            loanId = loan.Id;
        }

        // Act
        var result = await _service.RepayLoanAsync(loanId);

        // Assert
        Assert.IsTrue(result.Success);

        using var db = new BankAppDbContext(_options);
        var accVerify = await db.BankAccounts.FirstAsync(a => a.UserId == "sender-id");
        var loanVerify = await db.LoanRequests.FirstAsync(l => l.Id == loanId);

        Assert.AreEqual(1500m, accVerify.Balance); // 2000 - 500
        Assert.AreEqual(LoanStatus.Paid, loanVerify.Status);
    }
}
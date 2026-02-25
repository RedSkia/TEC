using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Lending;
using BankApp.Data.Entities.Market;
using BankApp.Services;
using BankApp.Tests;
using Microsoft.EntityFrameworkCore;

[TestClass]
public class CRUDServiceTests : BankAppDbContextTests
{
    // --- HELPERS ---
    private async Task<ApplicationUser> SeedUserAsync()
    {
        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), FullName = "Test Person", UserName = $"test_{Guid.NewGuid()}@bank.dk", Email = "test@bank.dk" };
        Context.Users.Add(user);
        await Context.SaveChangesAsync();
        return user;
    }

    private async Task<BankAccount> SeedAccountAsync(string userId)
    {
        var account = new BankAccount { AccountNumber = $"DK-{Guid.NewGuid().ToString()[..8]}", UserId = userId, Balance = 1000 };
        Context.BankAccounts.Add(account);
        await Context.SaveChangesAsync();
        return account;
    }

    // --- AUTH ENTITY TESTS ---

    [TestMethod, Priority(2)]
    public async Task Address_FullLifecycle_ShouldWork()
    {
        var user = await SeedUserAsync();
        var service = new CRUDService<Address>(Context);
        var addr = new Address { Street = "Main St", City = "Roskilde", ZipCode = "4000", UserId = user.Id };

        // Create
        var created = await service.CreateAsync(addr);
        Assert.AreNotEqual(0, created.Id);

        // Update
        created.City = "Copenhagen";
        var success = await service.UpdateAsync(created.Id, created);
        Assert.IsTrue(success);

        var updated = await service.GetByIdAsync(created.Id);
        Assert.AreEqual("Copenhagen", updated?.City);
    }

    [TestMethod, Priority(2)]
    public async Task LoginActivity_Should_Record_Logins()
    {
        var user = await SeedUserAsync();
        var service = new CRUDService<LoginActivity>(Context);
        var log = new LoginActivity { IpAddress = "127.0.0.1", Status = "Success", UserId = user.Id };

        await service.CreateAsync(log);

        var logs = await service.GetAllAsync();
        Assert.IsTrue(logs.Any(l => l.UserId == user.Id));
    }

    // --- BANKING ENTITY TESTS ---

    [TestMethod, Priority(2)]
    public async Task Card_Should_Support_MMYY_Validation_And_Blocking()
    {
        var user = await SeedUserAsync();
        var acc = await SeedAccountAsync(user.Id);
        var service = new CRUDService<Card>(Context);

        var card = new Card
        {
            CardNumber = "1234567812345678",
            ExpiryDate = "12/28",
            Cvc = "123",
            BankAccountId = acc.Id,
            IsBlocked = false
        };

        await service.CreateAsync(card);

        // Test Blocking via Update
        card.IsBlocked = true;
        await service.UpdateAsync(card.Id, card);

        var dbCard = await service.GetByIdAsync(card.Id);
        Assert.IsTrue(dbCard!.IsBlocked);
    }

    [TestMethod, Priority(2)]
    public async Task Transaction_Should_Store_Decimal_Precision()
    {
        var user = await SeedUserAsync();
        var acc = await SeedAccountAsync(user.Id);
        var service = new CRUDService<Transaction>(Context);

        var tx = new Transaction
        {
            Amount = 1234.56m,
            Type = TransactionType.Deposit,
            BankAccountId = acc.Id,
            Note = "Salary"
        };

        await service.CreateAsync(tx);
        var saved = await service.GetByIdAsync(tx.Id);
        Assert.AreEqual(1234.56m, saved?.Amount);
    }

    // --- LENDING ENTITY TESTS ---

    [TestMethod, Priority(2)]
    public async Task LoanRequest_Status_Workflow_ShouldWork()
    {
        var user = await SeedUserAsync();
        var acc = await SeedAccountAsync(user.Id);
        var service = new CRUDService<LoanRequest>(Context);

        var loan = new LoanRequest
        {
            Amount = 50000,
            InterestRate = 5.5m,
            Status = LoanStatus.Open,
            BankAccountId = acc.Id,
            MessageFromCustomer = "Need a new car"
        };

        await service.CreateAsync(loan);

        // Update status to UnderReview
        loan.Status = LoanStatus.UnderReview;
        await service.UpdateAsync(loan.Id, loan);

        var updated = await service.GetByIdAsync(loan.Id);
        Assert.AreEqual(LoanStatus.UnderReview, updated?.Status);
    }

    // --- MARKET ENTITY TESTS ---

    [TestMethod, Priority(2)]
    public async Task Investment_Relation_To_Stock_ShouldWork()
    {
        var user = await SeedUserAsync();
        var acc = await SeedAccountAsync(user.Id);

        // Seed Stock
        var stock = new Stock { Name = "Tesla", Ticker = "TSLA", CurrentPrice = 250.00m };
        Context.Stocks.Add(stock);
        await Context.SaveChangesAsync();

        var service = new CRUDService<Investment>(Context);
        var invest = new Investment { Quantity = 10.5m, BankAccountId = acc.Id, StockId = stock.Id };

        await service.CreateAsync(invest);

        var dbInvest = await Context.Investments
            .Include(i => i.Stock)
            .FirstOrDefaultAsync(i => i.Id == invest.Id);

        Assert.IsNotNull(dbInvest?.Stock);
        Assert.AreEqual("TSLA", dbInvest.Stock.Ticker);
    }

    [TestMethod, Priority(2)]
    public async Task ExchangeRate_CRUD_ShouldWork()
    {
        var service = new CRUDService<ExchangeRate>(Context);
        var rate = new ExchangeRate { CurrencyCode = "EUR", Rate = 7.45m };

        await service.CreateAsync(rate);
        var result = await service.GetAllAsync();

        Assert.IsTrue(result.Any(r => r.CurrencyCode == "EUR"));
    }

    // --- GENERIC ERROR HANDLING ---

    [TestMethod, Priority(2)]
    public async Task Update_NonExistent_Id_Should_Return_False()
    {
        var service = new CRUDService<Stock>(Context);
        var fakeStock = new Stock { Id = 9999, Name = "Ghost", Ticker = "GHOST" };

        var result = await service.UpdateAsync(9999, fakeStock);

        Assert.IsFalse(result);
    }
}
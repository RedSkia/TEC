namespace BankApp.Tests;

public class CRUDServiceTests : BankAppDbContextTests
{
    // --- HJÆLPE METODER (Seed Data for Foreign Keys) ---

    private async Task<ApplicationUser> SeedUserAsync()
    {
        var user = new ApplicationUser { Id = Guid.NewGuid().ToString(), FullName = "Test Person", UserName = "test@bank.dk" };
        Context.Users.Add(user);
        await Context.SaveChangesAsync();
        return user;
    }

    private async Task<BankAccount> SeedAccountAsync(string userId)
    {
        var account = new BankAccount { AccountNumber = "DK-" + Guid.NewGuid().ToString()[..8], UserId = userId, Balance = 1000 };
        Context.BankAccounts.Add(account);
        await Context.SaveChangesAsync();
        return account;
    }

    // --- TESTS ---

    [Fact]
    public async Task Create_Stock_ShouldWork()
    {
        // Ingen FK nødvendig her
        var service = new CRUDService<Stock>(Context);
        var entity = new Stock { Name = "Tesla", Ticker = "TSLA", CurrentPrice = 200 };

        var result = await service.CreateAsync(entity);

        Assert.True(result.Id > 0);
        Assert.NotNull(await Context.Stocks.FindAsync(result.Id));
    }

    [Fact]
    public async Task Create_Address_ShouldWork()
    {
        // KRÆVER: UserId
        var user = await SeedUserAsync();
        var service = new CRUDService<Address>(Context);
        var entity = new Address { Street = "Main St 1", City = "Roskilde", ZipCode = "4000", UserId = user.Id };

        var result = await service.CreateAsync(entity);

        Assert.True(result.Id > 0);
        Assert.Equal("Roskilde", (await Context.Addresses.FindAsync(result.Id))?.City);
    }

    [Fact]
    public async Task Create_BankAccount_ShouldWork()
    {
        // KRÆVER: UserId
        var user = await SeedUserAsync();
        var service = new CRUDService<BankAccount>(Context);
        var entity = new BankAccount { AccountNumber = "DK001", Balance = 5000, UserId = user.Id };

        var result = await service.CreateAsync(entity);

        Assert.True(result.Id > 0);
        Assert.Equal("DK001", (await Context.BankAccounts.FindAsync(result.Id))?.AccountNumber);
    }

    [Fact]
    public async Task Create_Card_ShouldWork()
    {
        // KRÆVER: BankAccountId
        var user = await SeedUserAsync();
        var account = await SeedAccountAsync(user.Id);
        var service = new CRUDService<Card>(Context);
        var entity = new Card { CardNumber = "1234-5678", ExpiryDate = "12/28", Cvc = "123", BankAccountId = account.Id };

        var result = await service.CreateAsync(entity);

        Assert.True(result.Id > 0);
        Assert.NotNull(await Context.Cards.FindAsync(result.Id));
    }

    [Fact]
    public async Task Create_Transaction_ShouldWork()
    {
        // KRÆVER: BankAccountId
        var user = await SeedUserAsync();
        var account = await SeedAccountAsync(user.Id);
        var service = new CRUDService<Transaction>(Context);
        var entity = new Transaction { Amount = 1000, Type = TransactionType.Deposit, BankAccountId = account.Id };

        var result = await service.CreateAsync(entity);

        Assert.True(result.Id > 0);
        Assert.Equal(1000, (await Context.Transactions.FindAsync(result.Id))?.Amount);
    }

    [Fact]
    public async Task Create_Investment_ShouldWork()
    {
        // KRÆVER: BankAccountId OG StockId
        var user = await SeedUserAsync();
        var account = await SeedAccountAsync(user.Id);
        var stock = new Stock { Name = "Apple", Ticker = "AAPL", CurrentPrice = 150 };
        Context.Stocks.Add(stock);
        await Context.SaveChangesAsync();

        var service = new CRUDService<Investment>(Context);
        var entity = new Investment { Quantity = 10, BankAccountId = account.Id, StockId = stock.Id };

        var result = await service.CreateAsync(entity);

        Assert.True(result.Id > 0);
        Assert.NotNull(await Context.Investments.FindAsync(result.Id));
    }

    [Fact]
    public async Task Create_LoanRequest_ShouldWork()
    {
        // KRÆVER: BankAccountId
        var user = await SeedUserAsync();
        var account = await SeedAccountAsync(user.Id);
        var service = new CRUDService<LoanRequest>(Context);
        var entity = new LoanRequest
        {
            Amount = 25000,
            Status = LoanStatus.UnderReview,
            BankAccountId = account.Id,
            MessageFromCustomer = "Need money for car",
            TicketReference = "REF-123"
        };

        var result = await service.CreateAsync(entity);

        Assert.True(result.Id > 0);
        Assert.Equal(25000, (await Context.LoanRequests.FindAsync(result.Id))?.Amount);
    }
}
using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using BankApp.Data;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Market;

namespace BankApp.Services;

public class StockMarketService(IDbContextFactory<BankAppDbContext> dbFactory) : BackgroundService
{
    public event Action? OnMarketUpdated;
    // --- BACKGROUND ENGINE (The Worker) ---
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await UpdateMarketPrices();
            // Notify anyone listening (like our UI)
            OnMarketUpdated?.Invoke();
            await Task.Delay(1000, stoppingToken);
        }
    }

    private async Task UpdateMarketPrices()
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var stocks = await db.Stocks.ToListAsync();
        foreach (var stock in stocks)
        {
            decimal fluctuation = GetRandomDecimal(-0.025m, 0.025m);
            stock.CurrentPrice = Math.Round(stock.CurrentPrice * (1 + fluctuation), 2);

            // Hard Clamps Logic
            if (stock.CurrentPrice <= 0.10m) stock.CurrentPrice = 0.15m;
            if (stock.CurrentPrice >= 5000m) stock.CurrentPrice = 4800m;

            db.StockHistory.Add(new StockHistory { StockId = stock.Id, Price = stock.CurrentPrice, Timestamp = DateTime.UtcNow });
        }
        await db.SaveChangesAsync();
    }

    // --- TRADE EXECUTION ---
    public async Task<(bool Success, string Message)> ExecuteTrade(string? userId, int stockId, decimal quantity, bool isBuy)
    {
        if (string.IsNullOrEmpty(userId) || quantity <= 0) return (false, "Invalid Trade.");
        using var db = await dbFactory.CreateDbContextAsync();
        var strategy = db.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync(async () => {
            using var tx = await db.Database.BeginTransactionAsync();
            try
            {
                var acc = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == userId);
                var stock = await db.Stocks.FindAsync(stockId);
                if (acc == null || stock == null) return (false, "Missing data.");

                decimal totalValue = Math.Round(quantity * (stock.CurrentPrice * acc.CurrencyType.Rate), 2);
                var inv = await db.Investments.FirstOrDefaultAsync(i => i.BankAccountId == acc.Id && i.StockId == stockId);

                if (isBuy)
                {
                    if (acc.Balance < totalValue) return (false, "No money.");
                    acc.Balance -= totalValue;
                    if (inv == null) db.Investments.Add(new Investment { BankAccountId = acc.Id, StockId = stockId, Quantity = quantity });
                    else inv.Quantity += quantity;
                }
                else
                {
                    if (inv == null || inv.Quantity < quantity) return (false, "No shares.");
                    inv.Quantity -= quantity;
                    acc.Balance += totalValue;
                    if (inv.Quantity <= 0) db.Investments.Remove(inv);
                }

                db.Transactions.Add(new Transaction
                {
                    BankAccountId = acc.Id,
                    Amount = isBuy ? -totalValue : totalValue,
                    Type = isBuy ? TransactionType.Withdraw : TransactionType.Deposit,
                    TransactionReference = Guid.NewGuid().ToString("N")[..12].ToUpper(),
                    CreatedAt = DateTime.UtcNow
                });

                await db.SaveChangesAsync();
                await tx.CommitAsync();
                return (true, "Success");
            }
            catch (Exception ex) { return (false, ex.Message); }
        });
    }

    private decimal GetRandomDecimal(decimal min, decimal max)
    {
        var bytes = new byte[8];
        RandomNumberGenerator.Fill(bytes);
        return min + (decimal)(BitConverter.ToUInt64(bytes, 0) / (double)ulong.MaxValue * (double)(max - min));
    }
}
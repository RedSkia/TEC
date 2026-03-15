using System.Security.Cryptography;
using BankApp.Data;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Market;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Services;

public interface IStockService
{
    Task UpdateMarketPricesAsync();
    Task AdminAdjustPriceAsync(int stockId, decimal newPrice);
    Task<(bool Success, string Message)> ExecuteTradeAsync(string? userId, int stockId, decimal quantity, bool isBuy);
}

public class StockService(IDbContextFactory<BankAppDbContext> dbFactory) : IStockService
{
    public async Task UpdateMarketPricesAsync()
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var stocks = await db.Stocks.ToListAsync();

        foreach (var stock in stocks)
        {
            decimal fluctuation = GetRandomDecimal(-0.02m, 0.025m);
            decimal oldPrice = stock.CurrentPrice;
            decimal change = oldPrice * fluctuation;

            stock.CurrentPrice = Math.Round(oldPrice + change, 2);
            if (stock.CurrentPrice <= 0.01m) stock.CurrentPrice = 0.50m;

            db.StockHistory.Add(new StockHistory
            {
                StockId = stock.Id,
                Price = stock.CurrentPrice,
                Timestamp = DateTime.UtcNow
            });
        }
        await db.SaveChangesAsync();
    }

    public async Task<(bool Success, string Message)> ExecuteTradeAsync(string? userId, int stockId, decimal quantity, bool isBuy)
    {
        if (string.IsNullOrEmpty(userId)) return (false, "Authorization required.");
        if (quantity <= 0) return (false, "Invalid quantity.");

        using var db = await dbFactory.CreateDbContextAsync();
        var strategy = db.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await db.Database.BeginTransactionAsync();
            try
            {
                var account = await db.BankAccounts
                    .Include(a => a.CurrencyType)
                    .FirstOrDefaultAsync(a => a.UserId == userId);

                var stock = await db.Stocks.FindAsync(stockId);

                if (account == null || stock == null)
                    return (false, "Trade components missing.");

                decimal localPricePerShare = stock.CurrentPrice * account.CurrencyType.Rate;
                // Calculate total based on full decimal quantity
                decimal totalTradeValue = Math.Round(quantity * localPricePerShare, 2);

                var investment = await db.Investments
                    .FirstOrDefaultAsync(i => i.BankAccountId == account.Id && i.StockId == stockId);

                if (isBuy)
                {
                    if (account.Balance < totalTradeValue)
                        return (false, "Insufficient funds.");

                    account.Balance -= totalTradeValue;

                    if (investment == null)
                    {
                        db.Investments.Add(new Investment
                        {
                            BankAccountId = account.Id,
                            StockId = stockId,
                            Quantity = quantity // FIXED: Removed (int)
                        });
                    }
                    else
                    {
                        investment.Quantity += quantity; // FIXED: Removed (int)
                    }
                }
                else // SELL
                {
                    // FIXED: Use decimal comparison for assets
                    if (investment == null || investment.Quantity < quantity)
                        return (false, "Insufficient assets.");

                    investment.Quantity -= quantity; // FIXED: Removed (int)
                    account.Balance += totalTradeValue;

                    if (investment.Quantity <= 0) db.Investments.Remove(investment);
                }

                db.Transactions.Add(new Transaction
                {
                    BankAccountId = account.Id,
                    Amount = isBuy ? -totalTradeValue : totalTradeValue,
                    CurrencyTypeId = account.CurrencyTypeId,
                    TransactionReference = Guid.NewGuid().ToString("N").ToUpper().Substring(0, 12),
                    Type = isBuy ? TransactionType.Withdraw : TransactionType.Deposit,
                    Note = $"{(isBuy ? "Bought" : "Sold")} {quantity:N4} {stock.Ticker} @@ {localPricePerShare:N2}",
                    CreatedAt = DateTime.UtcNow
                });

                await db.SaveChangesAsync();
                await transaction.CommitAsync();

                return (true, "Success");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return (false, $"Execution error: {ex.Message}");
            }
        });
    }

    public async Task AdminAdjustPriceAsync(int stockId, decimal newPrice)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var stock = await db.Stocks.FindAsync(stockId);
        if (stock != null)
        {
            stock.CurrentPrice = newPrice;
            db.StockHistory.Add(new StockHistory { StockId = stock.Id, Price = newPrice, Timestamp = DateTime.UtcNow });
            await db.SaveChangesAsync();
        }
    }

    private decimal GetRandomDecimal(decimal min, decimal max)
    {
        var range = (double)(max - min);
        var bytes = new byte[8];
        RandomNumberGenerator.Fill(bytes);
        var randomDouble = BitConverter.ToUInt64(bytes, 0) / (double)ulong.MaxValue;
        return min + (decimal)(randomDouble * range);
    }
}
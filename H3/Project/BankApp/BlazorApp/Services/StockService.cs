// Services/StockService.cs
using System.Security.Cryptography;
using BankApp.Data;
using BankApp.Data.Entities.Market;
using BankApp.Data.Entities.Banking;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Services;

public interface IStockService
{
    Task UpdateMarketPricesAsync();
    Task AdminAdjustPriceAsync(int stockId, decimal newPrice);
    Task<(bool Success, string Message)> ExecuteTradeAsync(string? userId, int stockId, decimal quantity, bool isBuy);
}

public class StockService : IStockService
{
    private readonly IDbContextFactory<BankAppDbContext> _dbFactory;

    public StockService(IDbContextFactory<BankAppDbContext> dbFactory)
    {
        _dbFactory = dbFactory;
    }

    public async Task UpdateMarketPricesAsync()
    {
        using var db = await _dbFactory.CreateDbContextAsync();
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
        // 1. Server-side login check
        if (string.IsNullOrEmpty(userId)) return (false, "You must be logged in to trade.");
        if (quantity <= 0) return (false, "Invalid quantity.");

        using var db = await _dbFactory.CreateDbContextAsync();

        // Load User + Account + Stock
        var user = await db.Users
            .Include(u => u.BankAccount)
            .FirstOrDefaultAsync(u => u.Id == userId);

        var stock = await db.Stocks.FindAsync(stockId);

        if (user == null || user.BankAccount == null || stock == null)
            return (false, "System error: Trade components not found.");

        decimal totalCost = stock.CurrentPrice * quantity;

        if (isBuy)
        {
            if (user.BankAccount.Balance < totalCost) return (false, "Insufficient balance.");

            user.BankAccount.Balance -= totalCost;
            // Add to investments (Simplified)
            db.Investments.Add(new Investment
            {
                BankAccountId = user.BankAccount.Id,
                StockId = stockId,
                Quantity = (int)quantity, // Assuming int for your entity
            });
        }
        else
        {
            // Sell logic: check if they own enough...
            return (false, "Sell logic pending portfolio implementation.");
        }

        await db.SaveChangesAsync();
        return (true, isBuy ? "Acquisition Complete." : "Asset Liquidated.");
    }

    public async Task AdminAdjustPriceAsync(int stockId, decimal newPrice)
    {
        using var db = await _dbFactory.CreateDbContextAsync();
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
using System.Security.Cryptography;
using BankApp.Data;
using BankApp.Data.Entities.Market;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Services;

public interface IStockService
{
    Task UpdateMarketPricesAsync();
    Task AdminAdjustPriceAsync(int stockId, decimal newPrice);
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
            // Secure random fluctuation: -2.0% to +2.5%
            decimal fluctuation = GetSecureRandomDecimal(-0.02m, 0.025m);
            decimal oldPrice = stock.CurrentPrice;
            decimal change = oldPrice * fluctuation;

            stock.CurrentPrice = Math.Round(oldPrice + change, 2);

            // Floor protection
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

    public async Task AdminAdjustPriceAsync(int stockId, decimal newPrice)
    {
        using var db = await _dbFactory.CreateDbContextAsync();
        var stock = await db.Stocks.FindAsync(stockId);

        if (stock != null)
        {
            stock.CurrentPrice = newPrice;
            db.StockHistory.Add(new StockHistory
            {
                StockId = stock.Id,
                Price = newPrice,
                Timestamp = DateTime.UtcNow
            });
            await db.SaveChangesAsync();
        }
    }

    private decimal GetSecureRandomDecimal(decimal min, decimal max)
    {
        var range = (double)(max - min);
        var bytes = new byte[8];
        RandomNumberGenerator.Fill(bytes);
        var randomDouble = BitConverter.ToUInt64(bytes, 0) / (double)ulong.MaxValue;
        return min + (decimal)(randomDouble * range);
    }
}
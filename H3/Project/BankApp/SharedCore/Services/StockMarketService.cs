using System.Security.Cryptography;
using System.Collections.Concurrent;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using SharedCore.Data;
using SharedCore.Entities.Banking;
using SharedCore.Entities.Market;

namespace SharedCore.Services;

public interface IStockMarketService
{
    event Action? OnMarketUpdated;
    MarketState GetGlobalState();
    MarketState GetStockState(int stockId);
    void SetGlobalOverride(MarketState state);
    void SetStockOverride(int stockId, MarketState state);
    Task<(bool Success, string Message)> ExecuteTrade(string? userId, int stockId, decimal quantity, bool isBuy);
}

public enum MarketState { Normal = 0, ForcedPump = 1, ForcedCrash = 2 }

public class StockMarketService(IDbContextFactory<BankAppDbContext> dbFactory) : BackgroundService, IStockMarketService
{
    public event Action? OnMarketUpdated;

    // VIGTIGT: Ingen 'static' her mere!
    private MarketState _globalState = MarketState.Normal;
    private ConcurrentDictionary<int, MarketState> _stockOverrides = new();

    public MarketState GetGlobalState() => _globalState;

    public MarketState GetStockState(int stockId)
    {
        if (_globalState != MarketState.Normal) return _globalState;
        return _stockOverrides.TryGetValue(stockId, out var state) ? state : MarketState.Normal;
    }

    public void SetGlobalOverride(MarketState state)
    {
        _globalState = state;
        _stockOverrides.Clear();
    }

    public void SetStockOverride(int stockId, MarketState state)
    {
        _globalState = MarketState.Normal;
        if (state == MarketState.Normal) _stockOverrides.TryRemove(stockId, out _);
        else _stockOverrides[stockId] = state;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await UpdateMarketPrices();
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
            MarketState activeState = GetStockState(stock.Id);
            decimal fluctuation;

            if (activeState != MarketState.Normal)
            {
                fluctuation = activeState == MarketState.ForcedPump
                    ? GetRandomDecimal(0.005m, 0.02m)
                    : GetRandomDecimal(-0.02m, -0.005m);
            }
            else
            {
                fluctuation = GetRandomDecimal(-0.003m, 0.003m);
            }

            stock.CurrentPrice = Math.Round(stock.CurrentPrice * (1 + fluctuation), 2);

            if (stock.CurrentPrice <= 0.01m) stock.CurrentPrice = 0.01m;
            if (stock.CurrentPrice >= 65535m) stock.CurrentPrice = 65535m;

            db.StockHistory.Add(new StockHistory
            {
                StockId = stock.Id,
                Price = stock.CurrentPrice,
                Timestamp = DateTime.UtcNow
            });
        }
        await db.SaveChangesAsync();
    }

    public async Task<(bool Success, string Message)> ExecuteTrade(string? userId, int stockId, decimal quantity, bool isBuy)
    {
        if (string.IsNullOrEmpty(userId) || quantity <= 0) return (false, "Invalid Trade Parameters.");

        using var db = await dbFactory.CreateDbContextAsync();
        var strategy = db.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync(async () => {
            using var tx = await db.Database.BeginTransactionAsync();
            try
            {
                var acc = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == userId);
                var stock = await db.Stocks.FindAsync(stockId);

                if (acc == null || stock == null) return (false, "Critical error: Missing account or asset data.");

                decimal totalValue = Math.Round(quantity * (stock.CurrentPrice * acc.CurrencyType.Rate), 2);
                var inv = await db.Investments.FirstOrDefaultAsync(i => i.BankAccountId == acc.Id && i.StockId == stockId);

                if (isBuy)
                {
                    if (acc.Balance < totalValue) return (false, "Insufficient capital for market entry.");
                    acc.Balance -= totalValue;
                    if (inv == null)
                        db.Investments.Add(new Investment { BankAccountId = acc.Id, StockId = stockId, Quantity = quantity });
                    else
                        inv.Quantity += quantity;
                }
                else
                {
                    if (inv == null || inv.Quantity < quantity) return (false, "Insufficient asset volume for liquidation.");
                    inv.Quantity -= quantity;
                    acc.Balance += totalValue;
                    if (inv.Quantity <= 0) db.Investments.Remove(inv);
                }

                db.Transactions.Add(new Transaction
                {
                    BankAccountId = acc.Id,
                    Amount = isBuy ? -totalValue : totalValue,
                    CurrencyTypeId = acc.CurrencyTypeId,
                    Type = isBuy ? TransactionType.Withdraw : TransactionType.Deposit,
                    Note = $"Market Execution: {(isBuy ? "Bought" : "Sold")} {quantity}x {stock.Ticker}",
                    TransactionReference = Guid.NewGuid().ToString("N")[..12].ToUpper(),
                    CreatedAt = DateTime.UtcNow
                });

                await db.SaveChangesAsync();
                await tx.CommitAsync();
                return (true, "Success");
            }
            catch (Exception ex) { return (false, $"System Fault: {ex.Message}"); }
        });
    }

    private decimal GetRandomDecimal(decimal min, decimal max)
    {
        var bytes = new byte[8];
        RandomNumberGenerator.Fill(bytes);
        return min + (decimal)(BitConverter.ToUInt64(bytes, 0) / (double)ulong.MaxValue * (double)(max - min));
    }
}
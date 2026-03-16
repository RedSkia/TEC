using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using SharedCore.Data;
using SharedCore.Entities.Banking;
using SharedCore.Entities.Market;

namespace SharedCore.Services;

public enum MarketState { Normal = 0, ForcedPump = 1, ForcedCrash = 2 }

public class StockMarketService(IDbContextFactory<BankAppDbContext> dbFactory) : BackgroundService
{
    public event Action? OnMarketUpdated;

    // --- MANIPULATION STATE ---
    private static MarketState _globalState = MarketState.Normal;
    private static Dictionary<int, MarketState> _stockOverrides = new();

    // --- GETTERS ---
    public MarketState GetGlobalState() => _globalState;

    public MarketState GetStockState(int stockId)
    {
        // Global override takes priority over individual settings
        if (_globalState != MarketState.Normal) return _globalState;
        return _stockOverrides.ContainsKey(stockId) ? _stockOverrides[stockId] : MarketState.Normal;
    }

    // --- ADMIN COMMANDS ---
    public void SetGlobalOverride(MarketState state)
    {
        _globalState = state;
        _stockOverrides.Clear(); // Reset individual targets when a global command is issued
    }

    public void SetStockOverride(int stockId, MarketState state)
    {
        _globalState = MarketState.Normal; // Breaking global state for specific targeting
        if (state == MarketState.Normal) _stockOverrides.Remove(stockId);
        else _stockOverrides[stockId] = state;
    }

    // --- BACKGROUND WORKER ---
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
                // Forced manipulation: High velocity moves
                fluctuation = activeState == MarketState.ForcedPump
                    ? GetRandomDecimal(0.04m, 0.08m)
                    : GetRandomDecimal(-0.08m, -0.04m);
            }
            else
            {
                // Normal market behavior
                fluctuation = GetRandomDecimal(-0.025m, 0.025m);
            }

            stock.CurrentPrice = Math.Round(stock.CurrentPrice * (1 + fluctuation), 2);

            // Floor and Ceiling Clamps
            if (stock.CurrentPrice <= 0.10m) stock.CurrentPrice = 0.15m;
            if (stock.CurrentPrice >= 5000m) stock.CurrentPrice = 4800m;

            // Log history for charts
            db.StockHistory.Add(new StockHistory
            {
                StockId = stock.Id,
                Price = stock.CurrentPrice,
                Timestamp = DateTime.UtcNow
            });
        }
        await db.SaveChangesAsync();
    }

    // --- TRADE EXECUTION (PRESERVED) ---
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

                // Log to Transactions Ledger
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
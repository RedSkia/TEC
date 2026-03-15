using BankApp.Data;
using BankApp.Data.Entities.Banking;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Services;

public interface ICurrencyService
{
    Task<List<CurrencyType>> GetAvailableCurrencies();
    Task<bool> UpdateAccountCurrency(string userId, int targetCurrencyId);
}

public class CurrencyService(IDbContextFactory<BankAppDbContext> dbFactory) : ICurrencyService
{
    public async Task<List<CurrencyType>> GetAvailableCurrencies()
    {
        using var db = await dbFactory.CreateDbContextAsync();
        return await db.CurrencyTypes.AsNoTracking().ToListAsync();
    }

    public async Task<bool> UpdateAccountCurrency(string userId, int targetCurrencyId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        using var transaction = await db.Database.BeginTransactionAsync();

        try
        {
            var account = await db.BankAccounts
                .Include(a => a.CurrencyType)
                .FirstOrDefaultAsync(a => a.UserId == userId);

            var target = await db.CurrencyTypes.FindAsync(targetCurrencyId);

            // Validation: Ensure account exists, target exists, and it's actually a change
            if (account == null || target == null || account.CurrencyTypeId == targetCurrencyId)
                return false;

            decimal oldBalance = account.Balance;

            // Conversion logic: (Current / CurrentRate) * TargetRate
            decimal baseBalance = account.Balance / account.CurrencyType.Rate;
            decimal newBalance = Math.Round(baseBalance * target.Rate, 2);

            string oldCode = account.CurrencyType.CurrencyCode;

            // Update Account
            account.Balance = newBalance;
            account.CurrencyTypeId = target.Id;

            // Log Transaction
            db.Transactions.Add(new Transaction
            {
                BankAccountId = account.Id,
                Amount = newBalance - oldBalance, // The difference in local value
                CurrencyTypeId = target.Id,
                TransactionReference = Guid.NewGuid().ToString("N").ToUpper().Substring(0, 12),
                Type = TransactionType.Exchange,
                Note = $"Currency Swap: {oldCode} to {target.CurrencyCode}",
                CreatedAt = DateTime.UtcNow
            });

            await db.SaveChangesAsync();
            await transaction.CommitAsync();
            return true;
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            return false;
        }
    }
}
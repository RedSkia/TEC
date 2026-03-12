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
        return await db.CurrencyTypes.ToListAsync();
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

            if (account == null || target == null || account.CurrencyTypeId == targetCurrencyId)
                return false;

            // 1. Calculate Balance
            decimal baseBalance = account.Balance / account.CurrencyType.Rate;
            decimal newBalance = baseBalance * target.Rate;

            // 2. Update Account
            string oldCode = account.CurrencyType.CurrencyCode;
            account.Balance = Math.Round(newBalance, 2);
            account.CurrencyTypeId = target.Id;

            // 3. Log the Exchange - FIXED: Added required fields
            db.Transactions.Add(new Transaction
            {
                BankAccountId = account.Id,
                Amount = 0, // Exchange doesn't change value, just currency
                CurrencyTypeId = target.Id, // REQUIRED
                TransactionReference = Guid.NewGuid().ToString("N").ToUpper().Substring(0, 12), // REQUIRED
                Type = TransactionType.Exchange,
                Note = $"Converted from {oldCode} to {target.CurrencyCode} (Rate: {target.Rate:F4})",
                CreatedAt = DateTime.UtcNow
            });

            await db.SaveChangesAsync();
            await transaction.CommitAsync();
            return true;
        }
        catch
        {
            await transaction.RollbackAsync();
            return false;
        }
    }
}
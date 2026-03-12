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

            decimal oldBalance = account.Balance;
            decimal baseBalance = account.Balance / account.CurrencyType.Rate;
            decimal newBalance = baseBalance * target.Rate;

            string oldCode = account.CurrencyType.CurrencyCode;
            account.Balance = Math.Round(newBalance, 2);
            account.CurrencyTypeId = target.Id;

            db.Transactions.Add(new Transaction
            {
                BankAccountId = account.Id,
                Amount = account.Balance - oldBalance,
                CurrencyTypeId = target.Id,
                TransactionReference = Guid.NewGuid().ToString("N").ToUpper().Substring(0, 12),
                Type = TransactionType.Exchange,
                Note = $"Swap: {oldCode} -> {target.CurrencyCode}",
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
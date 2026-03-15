using BankApp.Data;
using BankApp.Data.Entities.Banking;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Services;

public interface ITransferService
{
    Task<(bool Success, string Message)> ExecuteTransferAsync(string senderId, string recipientId, decimal amount);
}

public class TransferService(IDbContextFactory<BankAppDbContext> dbFactory) : ITransferService
{
    public async Task<(bool Success, string Message)> ExecuteTransferAsync(string senderId, string recipientId, decimal amount)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        using var transaction = await db.Database.BeginTransactionAsync();

        try
        {
            // 1. Fetch both accounts with their rates
            var sender = await db.BankAccounts
                .Include(a => a.CurrencyType)
                .FirstOrDefaultAsync(a => a.UserId == senderId);

            var recipient = await db.BankAccounts
                .Include(a => a.CurrencyType)
                .FirstOrDefaultAsync(a => a.UserId == recipientId);

            if (sender == null || recipient == null)
                return (false, "One or more accounts could not be found.");

            if (sender.Balance < amount)
                return (false, "Insufficient funds.");

            // 2. Cross-Currency Calculation
            // amount is in sender's currency. Convert to base, then to recipient's currency.
            decimal baseAmount = amount / sender.CurrencyType.Rate;
            decimal receivedAmount = Math.Round(baseAmount * recipient.CurrencyType.Rate, 2);

            // 3. Update Balances
            sender.Balance -= amount;
            recipient.Balance += receivedAmount;

            var transferRef = Guid.NewGuid().ToString("N").ToUpper().Substring(0, 12);

            // 4. Create Transaction Logs
            var transactions = new List<Transaction>
            {
                new Transaction
                {
                    BankAccountId = sender.Id,
                    Amount = -amount,
                    CurrencyTypeId = sender.CurrencyTypeId,
                    TransactionReference = transferRef,
                    Type = TransactionType.Transfer,
                    Note = $"Sent to {recipient.AccountNumber}",
                    CreatedAt = DateTime.UtcNow
                },
                new Transaction
                {
                    BankAccountId = recipient.Id,
                    Amount = receivedAmount,
                    CurrencyTypeId = recipient.CurrencyTypeId,
                    TransactionReference = transferRef,
                    Type = TransactionType.Transfer,
                    Note = $"Received from {sender.AccountNumber}",
                    CreatedAt = DateTime.UtcNow
                }
            };

            db.Transactions.AddRange(transactions);

            // 5. Atomic Save
            await db.SaveChangesAsync();
            await transaction.CommitAsync();

            return (true, "Success");
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            // Log 'ex' to your system console/logs to find the exact database constraint violation
            return (false, $"System error: {ex.Message}");
        }
    }
}
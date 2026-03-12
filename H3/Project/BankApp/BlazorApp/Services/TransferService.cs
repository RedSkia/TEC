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
            var sender = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == senderId);
            var recipient = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == recipientId);

            if (sender == null || recipient == null) return (false, "Account error.");
            if (sender.Balance < amount) return (false, "Insufficient funds.");

            decimal baseAmount = amount / sender.CurrencyType.Rate;
            decimal receivedAmount = Math.Round(baseAmount * recipient.CurrencyType.Rate, 2);

            sender.Balance -= amount;
            recipient.Balance += receivedAmount;

            db.Transactions.Add(new Transaction
            {
                BankAccountId = sender.Id,
                Amount = -amount,
                CurrencyTypeId = sender.CurrencyTypeId,
                TransactionReference = Guid.NewGuid().ToString("N").ToUpper().Substring(0, 12),
                Type = TransactionType.Transfer,
                Note = $"Transfer to {recipient.AccountNumber}",
                CreatedAt = DateTime.UtcNow
            });

            db.Transactions.Add(new Transaction
            {
                BankAccountId = recipient.Id,
                Amount = receivedAmount,
                CurrencyTypeId = recipient.CurrencyTypeId,
                TransactionReference = Guid.NewGuid().ToString("N").ToUpper().Substring(0, 12),
                Type = TransactionType.Transfer,
                Note = $"Transfer from {sender.AccountNumber}",
                CreatedAt = DateTime.UtcNow
            });

            await db.SaveChangesAsync();
            await transaction.CommitAsync();
            return (true, "Success");
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return (false, "System error during transfer.");
        }
    }
}
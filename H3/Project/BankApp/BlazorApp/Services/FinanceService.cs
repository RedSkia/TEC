using Microsoft.EntityFrameworkCore;
using BankApp.Data;
using BankApp.Data.Entities.Banking;

namespace BankApp.Services;

public class FinanceService(IDbContextFactory<BankAppDbContext> dbFactory)
{
    private string GenRef() => Guid.NewGuid().ToString("N").ToUpper()[..12];

    // --- TRANSFERS & CURRENCY ---
    public async Task<(bool Success, string Message)> ExecuteTransfer(string senderId, string recipientId, decimal amount)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        using var transaction = await db.Database.BeginTransactionAsync();
        try {
            var s = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == senderId);
            var r = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == recipientId);

            if (s == null || r == null || s.Balance < amount) return (false, "Invalid accounts or funds.");

            decimal received = Math.Round((amount / s.CurrencyType.Rate) * r.CurrencyType.Rate, 2);
            s.Balance -= amount;
            r.Balance += received;

            db.Transactions.AddRange(
                new Transaction { BankAccountId = s.Id, Amount = -amount, CurrencyTypeId = s.CurrencyTypeId, TransactionReference = GenRef(), Type = TransactionType.Transfer, Note = $"To {r.AccountNumber}", CreatedAt = DateTime.UtcNow },
                new Transaction { BankAccountId = r.Id, Amount = received, CurrencyTypeId = r.CurrencyTypeId, TransactionReference = GenRef(), Type = TransactionType.Transfer, Note = $"From {s.AccountNumber}", CreatedAt = DateTime.UtcNow }
            );

            await db.SaveChangesAsync();
            await transaction.CommitAsync();
            return (true, "Success");
        } catch (Exception ex) { return (false, ex.Message); }
    }

    public async Task<bool> UpdateAccountCurrency(string userId, int targetId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var acc = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == userId);
        var target = await db.CurrencyTypes.FindAsync(targetId);
        if (acc == null || target == null || acc.CurrencyTypeId == targetId) return false;

        acc.Balance = Math.Round((acc.Balance / acc.CurrencyType.Rate) * target.Rate, 2);
        acc.CurrencyTypeId = targetId;
        return await db.SaveChangesAsync() > 0;
    }

    // --- LOANS & GENERIC CRUD ---
    public async Task<List<T>> GetList<T>() where T : class 
    {
        using var db = await dbFactory.CreateDbContextAsync();
        return await db.Set<T>().AsNoTracking().ToListAsync();
    }

    public async Task<bool> SaveLoan(LoanRequest request)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        request.CreatedAt = DateTime.UtcNow;
        db.LoanRequests.Add(request);
        return await db.SaveChangesAsync() > 0;
    }
    // --- LOAN OFFICER PROTOCOLS ---

    public async Task<List<LoanRequest>> GetAllLoanRequestsAsync()
    {
        using var db = await dbFactory.CreateDbContextAsync();
        return await db.LoanRequests
            .Include(l => l.CurrencyType)
            .Include(l => l.BankAccount)
                .ThenInclude(b => b.User) // We need this to see WHO is asking
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();
    }

    public async Task<bool> UpdateLoanStatusAsync(int loanId, LoanStatus status, string? officerId, string? response = null)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var loan = await db.LoanRequests.FindAsync(loanId);
        if (loan == null) return false;

        loan.Status = status;

        if (!string.IsNullOrEmpty(officerId))
            loan.AssignedOfficerId = officerId;

        if (!string.IsNullOrEmpty(response))
            loan.ResponseFromOfficer = response;

        // Logic: If approved, we should actually deposit the money!
        if (status == LoanStatus.Approved)
        {
            var account = await db.BankAccounts.FindAsync(loan.BankAccountId);
            if (account != null)
            {
                account.Balance += loan.Amount;

                // Add a transaction record for the deposit
                db.Transactions.Add(new Transaction
                {
                    BankAccountId = account.Id,
                    Amount = loan.Amount,
                    CurrencyTypeId = loan.CurrencyTypeId,
                    Type = TransactionType.Loan, // Ensure you have this in your Enum
                    Note = $"LOAN_PROCEEDS: {loan.RequestReference.Substring(0, 8)}",
                    TransactionReference = Guid.NewGuid().ToString("N").ToUpper()[..12]
                });
            }
        }

        return await db.SaveChangesAsync() > 0;
    }
}
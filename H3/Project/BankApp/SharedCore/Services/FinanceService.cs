using Microsoft.EntityFrameworkCore;
using SharedCore.Data;
using SharedCore.Entities.Auth;
using SharedCore.Entities.Banking;
using SharedCore.Entities.Lending;

namespace SharedCore.Services;

public class FinanceService(IDbContextFactory<BankAppDbContext> dbFactory)
{
    public string GenRef() => Guid.NewGuid().ToString("N").ToUpper()[..12];

    public void AppendTransaction(BankAppDbContext db, int accountId, decimal amount, int currencyId, TransactionType type, string note)
    {
        db.Transactions.Add(new Transaction
        {
            BankAccountId = accountId,
            Amount = amount,
            CurrencyTypeId = currencyId,
            Type = type,
            Note = note,
            TransactionReference = GenRef(),
            CreatedAt = DateTime.UtcNow
        });
    }

    // --- ADMIN OVERRIDE PROTOCOLS ---
    public async Task<bool> AdjustUserBalance(string userId, decimal amount, string reason)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var acc = await db.BankAccounts.FirstOrDefaultAsync(a => a.UserId == userId);
        if (acc == null) return false;

        acc.Balance += amount;
        AppendTransaction(db, acc.Id, amount, acc.CurrencyTypeId, TransactionType.Payment, $"SYSTEM_OVERRIDE: {reason}");

        return await db.SaveChangesAsync() > 0;
    }

    public async Task<List<ApplicationUser>> GetAdminTargetList()
    {
        using var db = await dbFactory.CreateDbContextAsync();
        return await db.Users
            .Include(u => u.BankAccount)
            .OrderByDescending(u => u.BankAccount.Balance)
            .AsNoTracking()
            .ToListAsync();
    }

    // --- TRANSFERS & CURRENCY ---
    public async Task<(bool Success, string Message)> ExecuteTransfer(string senderId, string recipientId, decimal amount)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var strategy = db.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await db.Database.BeginTransactionAsync();
            try
            {
                var s = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == senderId);
                var r = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == recipientId);

                if (s == null || r == null || s.Balance < amount) return (false, "Invalid accounts or insufficient funds.");

                decimal received = Math.Round((amount / s.CurrencyType.Rate) * r.CurrencyType.Rate, 2);
                s.Balance -= amount;
                r.Balance += received;

                AppendTransaction(db, s.Id, -amount, s.CurrencyTypeId, TransactionType.Transfer, $"Transfer sent to {r.AccountNumber}");
                AppendTransaction(db, r.Id, received, r.CurrencyTypeId, TransactionType.Transfer, $"Transfer received from {s.AccountNumber}");

                await db.SaveChangesAsync();
                await transaction.CommitAsync();
                return (true, "Success");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return (false, ex.Message);
            }
        });
    }

    public async Task<bool> UpdateAccountCurrency(string userId, int targetId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var acc = await db.BankAccounts.Include(a => a.CurrencyType).FirstOrDefaultAsync(a => a.UserId == userId);
        var target = await db.CurrencyTypes.FindAsync(targetId);
        if (acc == null || target == null || acc.CurrencyTypeId == targetId) return false;

        acc.Balance = Math.Round((acc.Balance / acc.CurrencyType.Rate) * target.Rate, 2);
        AppendTransaction(db, acc.Id, 0, targetId, TransactionType.Exchange, $"Currency protocol swapped to {target.CurrencyCode}");

        acc.CurrencyTypeId = targetId;
        return await db.SaveChangesAsync() > 0;
    }

    // --- LOANS & GENERIC ---
    public async Task<List<T>> GetList<T>() where T : class
    {
        using var db = await dbFactory.CreateDbContextAsync();
        return await db.Set<T>().AsNoTracking().ToListAsync();
    }

    public async Task<List<LoanRequest>> GetUserLoansAsync(int bankAccountId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        return await db.LoanRequests
            .Include(l => l.CurrencyType)
            .Where(l => l.BankAccountId == bankAccountId)
            .OrderByDescending(l => l.CreatedAt)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<bool> SaveLoan(LoanRequest request)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        request.CreatedAt = DateTime.UtcNow;
        db.LoanRequests.Add(request);
        return await db.SaveChangesAsync() > 0;
    }

    public async Task<bool> DeleteLoanRequestAsync(int loanId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var loan = await db.LoanRequests.FirstOrDefaultAsync(l => l.Id == loanId);
        if (loan == null || loan.Status != LoanStatus.Open) return false;
        db.LoanRequests.Remove(loan);
        return await db.SaveChangesAsync() > 0;
    }

    public async Task<(bool Success, string Message)> RepayLoanAsync(int loanId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var strategy = db.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await db.Database.BeginTransactionAsync();
            try
            {
                var loan = await db.LoanRequests.Include(l => l.BankAccount).FirstOrDefaultAsync(l => l.Id == loanId);
                if (loan == null || loan.Status != LoanStatus.Approved) return (false, "Invalid loan state.");
                if (loan.BankAccount.Balance < loan.Amount) return (false, "Insufficient balance.");

                loan.BankAccount.Balance -= loan.Amount;
                loan.Status = LoanStatus.Paid;
                AppendTransaction(db, loan.BankAccountId, -loan.Amount, loan.CurrencyTypeId, TransactionType.Loan, $"Loan Repayment: {loan.RequestReference[..8]}");

                await db.SaveChangesAsync();
                await transaction.CommitAsync();
                return (true, "Loan successfully repaid.");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return (false, ex.Message);
            }
        });
    }

    public async Task<List<LoanRequest>> GetAllLoanRequestsAsync()
    {
        using var db = await dbFactory.CreateDbContextAsync();
        return await db.LoanRequests
            .Include(l => l.CurrencyType)
            .Include(l => l.BankAccount).ThenInclude(b => b.User)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();
    }

    public async Task<bool> UpdateLoanStatusAsync(int loanId, LoanStatus status, string? officerId, string? response = null)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var strategy = db.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await db.Database.BeginTransactionAsync();
            try
            {
                var loan = await db.LoanRequests.FindAsync(loanId);
                if (loan == null) return false;

                loan.Status = status;
                if (!string.IsNullOrEmpty(officerId)) loan.AssignedOfficerId = officerId;
                if (!string.IsNullOrEmpty(response)) loan.ResponseFromOfficer = response;

                if (status == LoanStatus.Approved)
                {
                    var account = await db.BankAccounts.FindAsync(loan.BankAccountId);
                    if (account != null)
                    {
                        account.Balance += loan.Amount;
                        AppendTransaction(db, account.Id, loan.Amount, loan.CurrencyTypeId, TransactionType.Loan, $"Loan Disbursement: {loan.RequestReference[..8]}");
                    }
                }
                var success = await db.SaveChangesAsync() > 0;
                await transaction.CommitAsync();
                return success;
            }
            catch
            {
                await transaction.RollbackAsync();
                return false;
            }
        });
    }
}
using BankApp.Data;
using BankApp.Data.Entities.Lending;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Services;

public interface ILendingService
{
    Task<bool> SubmitLoanRequestAsync(LoanRequest request);
    Task<bool> DeleteLoanRequestAsync(int loanId);
}

public class LendingService(IDbContextFactory<BankAppDbContext> dbFactory) : ILendingService
{
    public async Task<bool> SubmitLoanRequestAsync(LoanRequest request)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        try
        {
            request.CreatedAt = DateTime.UtcNow;
            request.Status = LoanStatus.Open;
            db.LoanRequests.Add(request);
            await db.SaveChangesAsync();
            return true;
        }
        catch { return false; }
    }

    public async Task<bool> DeleteLoanRequestAsync(int loanId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        try
        {
            var loan = await db.LoanRequests.FindAsync(loanId);
            if (loan == null) return false;

            db.LoanRequests.Remove(loan);
            await db.SaveChangesAsync();
            return true;
        }
        catch { return false; }
    }
}
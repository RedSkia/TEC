namespace BankApp.Entities.Finance;

using BankApp.Entities.Auth;

public class Loan
{
    public int Id { get; set; }
    public decimal Principal { get; set; } // Hovedstol
    public double InterestRate { get; set; }

    // Type-Logik: Er det "Boliglån", "Billån" etc.
    public int LoanTypeId { get; set; }
    public virtual LoanType LoanType { get; set; } = null!;

    // 1:m Relation til BankUser
    public int BankUserId { get; set; }
    public virtual BankUser BankUser { get; set; } = null!;

    public virtual List<LoanPayment> LoanPayments { get; set; } = new();
}
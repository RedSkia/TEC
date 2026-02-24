namespace BankApp.Entities.Finance;

public class LoanPayment
{
    public int Id { get; set; }
    public decimal Amount { get; set; }
    public DateTime PaymentDate { get; set; }

    // 1:m Relation til Loan
    public int LoanId { get; set; }
    public virtual Loan Loan { get; set; } = null!;
}
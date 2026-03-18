using SharedCore.Entities.Auth;
using SharedCore.Entities.Lending;
using SharedCore.Entities.Market;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SharedCore.Entities.Banking;

public class BankAccount
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string AccountNumber { get; set; } = Guid.NewGuid().ToString().Substring(0, 8).ToUpper();

    [Column(TypeName = "decimal(18,2)")]
    public decimal Balance { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    [ForeignKey(nameof(UserId))]
    public virtual ApplicationUser User { get; set; } = null!;

    [Required]
    public int CurrencyTypeId { get; set; } = 1; // Default to EUR (Id 1)

    [ForeignKey(nameof(CurrencyTypeId))]
    public virtual CurrencyType CurrencyType { get; set; } = null!;

    public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    public virtual ICollection<LoanRequest> LoanRequests { get; set; } = new List<LoanRequest>();
    public virtual ICollection<Investment> Investments { get; set; } = new List<Investment>();
    // Intents where this account is receiving money
    public virtual ICollection<PaymentIntent> ReceivedPaymentIntents { get; set; } = new List<PaymentIntent>();

    // Intents where this account is paying money
    public virtual ICollection<PaymentIntent> SentPaymentIntents { get; set; } = new List<PaymentIntent>();
}
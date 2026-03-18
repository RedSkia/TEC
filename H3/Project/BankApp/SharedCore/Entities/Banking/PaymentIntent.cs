using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SharedCore.Entities.Banking;

public class PaymentIntent
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [Column(TypeName = "decimal(18, 2)")]
    public decimal Amount { get; set; }

    [Required]
    [StringLength(100)]
    public string MerchantName { get; set; } = string.Empty;

    [Required]
    [Url]
    [StringLength(500)]
    public string WebhookUrl { get; set; } = string.Empty;

    [Required]
    public PaymentIntentStatus Status { get; set; } = PaymentIntentStatus.Pending;

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // --- RELATIONSHIPS ---

    // The account that will receive the funds (Merchant)
    [Required]
    public int ReceiverBankAccountId { get; set; }
    [ForeignKey(nameof(ReceiverBankAccountId))]
    public virtual BankAccount ReceiverBankAccount { get; set; } = null!;

    // The account that pays (Customer)
    // Nullable because we don't know who is paying until they log in and authorize
    public int? SenderBankAccountId { get; set; }
    [ForeignKey(nameof(SenderBankAccountId))]
    public virtual BankAccount? SenderBankAccount { get; set; }
}
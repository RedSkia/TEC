using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Banking;

public class Card
{
    [Key]
    public int Id { get; set; }

    [Required]
    [CreditCard(ErrorMessage = "Invalid Card Number format")]
    public string CardNumber { get; set; } = string.Empty;

    public bool IsBlocked { get; set; } = false;

    [Required]
    [RegularExpression(@"^(0[1-9]|1[0-2])\/\d{2}$", ErrorMessage = "Use MM/YY format")]
    public string ExpiryDate { get; set; } = string.Empty;

    [Required]
    [StringLength(3, MinimumLength = 3, ErrorMessage = "CVC must be 3 digits")]
    public string Cvc { get; set; } = string.Empty;

    [Required]
    public int BankAccountId { get; set; }

    [ForeignKey(nameof(BankAccountId))]
    public virtual BankAccount BankAccount { get; set; } = null!;
}
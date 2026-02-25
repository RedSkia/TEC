using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Banking;

public class Card
{
    [Key]
    public int Id { get; set; }
    public string CardNumber { get; set; } = string.Empty;
    public bool IsBlocked { get; set; } = false;

    [Required]
    public int BankAccountId { get; set; }
    [ForeignKey(nameof(BankAccountId))]
    public virtual BankAccount BankAccount { get; set; } = null!;
}
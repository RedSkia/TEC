using Microsoft.AspNetCore.Components;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Banking;

public class Transaction
{
    [Key]
    public int Id { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }
    public string Note { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public TransactionType Type { get; set; } // Transfer, Withdraw, Deposit, LoanDisbursement

    [Required]
    public int BankAccountId { get; set; }
    [ForeignKey(nameof(BankAccountId))]
    public virtual BankAccount BankAccount { get; set; } = null!;
}
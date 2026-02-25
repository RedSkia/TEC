using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Market;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Banking;

public class BankAccount
{
    [Key]
    public int Id { get; set; }
    [Required]
    public string AccountNumber { get; set; } = string.Empty;

    [Column(TypeName = "decimal(18,2)")]
    public decimal Balance { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;
    [ForeignKey(nameof(UserId))]
    public virtual ApplicationUser User { get; set; } = null!;

    // Alt finansielt ejer kontoen
    public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    public virtual ICollection<Card> Cards { get; set; } = new List<Card>();
    public virtual ICollection<LoanTicket> LoanTickets { get; set; } = new List<LoanTicket>();
    public virtual ICollection<Investment> Investments { get; set; } = new List<Investment>();
}
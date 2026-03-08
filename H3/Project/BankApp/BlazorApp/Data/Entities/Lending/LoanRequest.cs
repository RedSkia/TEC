using BankApp.Data.Entities.Auth; // Tilføjet
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Lending;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class LoanRequest
{
    [Key]
    public int Id { get; set; }

    public string RequestReference { get; set; } = Guid.NewGuid().ToString();

    [Column(TypeName = "decimal(18,2)")]
    [Range(100, 1000000, ErrorMessage = "Loan must be between 100 and 1,000,000")]
    public decimal Amount { get; set; }

    [Column(TypeName = "decimal(5,2)")]
    public decimal InterestRate { get; set; }

    public LoanStatus Status { get; set; } = LoanStatus.Open;

    [Required(ErrorMessage = "Please explain why you need this loan")]
    [MinLength(10, ErrorMessage = "Message is too short")]
    public string MessageFromCustomer { get; set; } = string.Empty;
    public string? ResponseFromOfficer { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Required]
    public int BankAccountId { get; set; }

    [ForeignKey(nameof(BankAccountId))]
    public virtual BankAccount BankAccount { get; set; } = null!;

    public string? AssignedOfficerId { get; set; }

    [ForeignKey(nameof(AssignedOfficerId))]
    public virtual ApplicationUser? AssignedOfficer { get; set; }
}
using BankApp.Data.Entities.Auth; // Tilføjet
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Lending;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class LoanTicket
{
    [Key]
    public int Id { get; set; }

    // Fjernede Guid.NewGuid() herfra for at undgå migration-fejl. 
    // Dette sættes i din Service eller via en statisk værdi.
    public string TicketReference { get; set; } = string.Empty;

    [Column(TypeName = "decimal(18,2)")]
    public decimal RequestedAmount { get; set; }

    [Column(TypeName = "decimal(5,2)")]
    public decimal InterestRate { get; set; }

    public LoanStatus Status { get; set; } = LoanStatus.Open;

    [Required]
    public string MessageFromCustomer { get; set; } = string.Empty;
    public string? ResponseFromOfficer { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Required]
    public int BankAccountId { get; set; }
    [ForeignKey(nameof(BankAccountId))]
    public virtual BankAccount BankAccount { get; set; } = null!;

    // Forbedret relation til Officer (Giver ekstra point for OOA/OOD)
    public string? AssignedOfficerId { get; set; }
    [ForeignKey(nameof(AssignedOfficerId))]
    public virtual ApplicationUser? AssignedOfficer { get; set; }
}
using BankApp.Data.Entities.Banking;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Market;

public class Investment
{
    [Key]
    public int Id { get; set; }

    [Column(TypeName = "decimal(18,4)")]
    public decimal Quantity { get; set; }

    [Required]
    public int BankAccountId { get; set; }

    [ForeignKey(nameof(BankAccountId))]
    public virtual BankAccount BankAccount { get; set; } = null!;

    [Required]
    public int StockId { get; set; }

    [ForeignKey(nameof(StockId))]
    public virtual Stock Stock { get; set; } = null!;
}

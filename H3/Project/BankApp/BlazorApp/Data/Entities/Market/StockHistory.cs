using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Market;

public class StockHistory
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int StockId { get; set; }

    [ForeignKey(nameof(StockId))]
    public virtual Stock Stock { get; set; } = null!;

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Price { get; set; }

    [Required]
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
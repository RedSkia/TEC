using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SharedCore.Entities.Market;

public class Stock
{
    [Key]
    public int Id { get; set; }

    [Required(ErrorMessage = "Company name is required")]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ticker symbol is required (e.g. AAPL)")]
    [StringLength(4, MinimumLength = 1)]
    public string Ticker { get; set; } = string.Empty;

    [Column(TypeName = "decimal(18,2)")]
    [Range(0.01, 1000000)]
    public decimal CurrentPrice { get; set; }

    public virtual ICollection<StockHistory> Histories { get; set; } = new List<StockHistory>();
}
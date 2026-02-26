using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Market;

public class Stock
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string Name { get; set; } = string.Empty;

    [Required]
    public string Ticker { get; set; } = string.Empty;

    [Column(TypeName = "decimal(18,2)")]
    public decimal CurrentPrice { get; set; }
}
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Market;

public class ExchangeRate
{
    [Key]
    public int Id { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    [Column(TypeName = "decimal(18,4)")]
    public decimal Rate { get; set; } // Sættes af Admin
}

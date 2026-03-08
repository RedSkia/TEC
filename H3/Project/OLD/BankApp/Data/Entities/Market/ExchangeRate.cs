using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Market;

public class ExchangeRate
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string CurrencyCode { get; set; } = "EUR";

    [Column(TypeName = "decimal(18,4)")]
    public decimal Rate { get; set; } // Sættes af Admin
}

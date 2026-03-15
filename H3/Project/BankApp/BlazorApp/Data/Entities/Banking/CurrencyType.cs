using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Banking;
public class CurrencyType
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string CurrencyCode { get; set; } = string.Empty;

    [Required]
    public string CurrencySymbol { get; set; } = string.Empty;

    [Required, Column(TypeName = "decimal(18,4)")]
    public decimal Rate { get; set; }
}
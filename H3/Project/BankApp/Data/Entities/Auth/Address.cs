using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Auth;

public class Address
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string Street { get; set; } = string.Empty;

    [Required]
    public string City { get; set; } = string.Empty;

    // Tilføjer Postnummer (ZipCode)
    [Required]
    [StringLength(10)] // Understøtter både danske (4 cifre) og internationale koder
    public string ZipCode { get; set; } = string.Empty;

    [Required]
    public string UserId { get; set; } = string.Empty;

    [ForeignKey(nameof(UserId))]
    public virtual ApplicationUser User { get; set; } = null!;
}
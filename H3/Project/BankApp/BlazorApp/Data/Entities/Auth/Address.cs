using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Auth;

public class Address
{
    [Key]
    public int Id { get; set; }

    [Required(ErrorMessage = "Street name is required")]
    public string Street { get; set; } = string.Empty;

    [Required(ErrorMessage = "City is required")]
    public string City { get; set; } = string.Empty;

    [Required(ErrorMessage = "Zip Code is required")]
    [RegularExpression(@"^\d{4}$", ErrorMessage = "Zip Code must be 4 digits")]
    public string ZipCode { get; set; } = string.Empty;

    [Required]
    public string UserId { get; set; } = string.Empty;

    [ForeignKey(nameof(UserId))]
    public virtual ApplicationUser User { get; set; } = null!;
}
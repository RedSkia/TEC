using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankApp.Data.Entities.Auth;

public class LoginActivity
{
    [Key]
    public int Id { get; set; }

    public DateTime LoginTime { get; set; } = DateTime.UtcNow;

    [Required]
    public string IpAddress { get; set; } = string.Empty;

    // Tilføjer status (f.eks. "Success", "Failed", "Wrong Password")
    [Required]
    public string Status { get; set; } = "Success";

    // Valgfrit: Tilføj Browser/Enhed info
    public string? UserAgent { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    [ForeignKey(nameof(UserId))]
    public virtual ApplicationUser User { get; set; } = null!;
}
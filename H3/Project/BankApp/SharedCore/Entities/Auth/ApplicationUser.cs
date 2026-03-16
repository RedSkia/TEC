using Microsoft.AspNetCore.Identity;
using SharedCore.Entities.Banking;
using System.ComponentModel.DataAnnotations;

namespace SharedCore.Entities.Auth;

public class ApplicationUser : IdentityUser
{
    [Required(ErrorMessage = "Full Name is required")]
    [StringLength(100, MinimumLength = 2)]
    public string FullName { get; set; } = string.Empty;
    public virtual Address Address { get; set; } = null!;
    public virtual BankAccount BankAccount { get; set; } = new();
    public virtual ICollection<LoginActivity> LoginActivities { get; set; } = new List<LoginActivity>();
}
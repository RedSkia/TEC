using BankApp.Data.Entities.Banking;
using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace BankApp.Data.Entities.Auth;

public class ApplicationUser : IdentityUser
{
    [Required(ErrorMessage = "Full Name is required")]
    [StringLength(100, MinimumLength = 2)]
    public string FullName { get; set; } = string.Empty;

    public virtual Address Address { get; set; } = null!;
    public virtual ICollection<BankAccount> BankAccounts { get; set; } = new List<BankAccount>();
    public virtual ICollection<LoginActivity> LoginActivities { get; set; } = new List<LoginActivity>();
}
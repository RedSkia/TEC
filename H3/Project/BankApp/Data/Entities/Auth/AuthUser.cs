using Microsoft.AspNetCore.Identity;
namespace BankApp.Entities.Auth;

public class AuthUser : IdentityUser
{
    // 1:1 Forbindelse til BankUser
    public virtual BankUser? BankUser { get; set; }
}
using Microsoft.AspNetCore.Identity;

namespace BankApp.Data.Entities;

// 1. IDENTITY OBJECT
public sealed class AuthUser : IdentityUser
{
    // Her kan du tilføje ekstra login-relaterede felter hvis nødvendigt
    // f.cs. public string RefreshToken { get; set; }
}
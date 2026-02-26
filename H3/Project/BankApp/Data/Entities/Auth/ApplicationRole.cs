using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace BankApp.Data.Entities.Auth;

public class ApplicationRole : IdentityRole
{
    [Required]
    public string RoleColor { get; set; } = "#808080";
}
namespace BankApp.Data.Entities;

// 2. BANK USER (Profilen der holdes af AuthUser)
public sealed class BankUser
{
    public int Id { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }

    // Link til Identity objektet
    public string AuthUserId { get; set; }
    public AuthUser AuthUser { get; set; }
}
namespace BankApp.Entities.Auth;

using BankApp.Entities.Core;

public class BankUser
{
    public int Id { get; set; }
    public string FullName { get; set; } = "";

    // FK til Identity
    public string AuthUserId { get; set; } = "";
    // 1:1 Forbindelse til AuthUser
    public virtual AuthUser AuthUser { get; set; } = null!;

    // m:n relation til konti (Den obligatoriske m:n)
    public virtual List<BankUserAccount> BankUserAccounts { get; set; } = new();
}
namespace BankApp.Entities.Core;

using BankApp.Entities.Auth;

public class BankUserAccount
{
    public int BankUserId { get; set; }
    public virtual BankUser BankUser { get; set; } = null!;

    public int AccountId { get; set; }
    public virtual Account Account { get; set; } = null!;
}
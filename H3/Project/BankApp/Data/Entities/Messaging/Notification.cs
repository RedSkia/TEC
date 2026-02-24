namespace BankApp.Entities.Messaging;

using BankApp.Entities.Auth;

public class Notification
{
    public int Id { get; set; }
    public string Message { get; set; } = "";
    public bool IsRead { get; set; } = false;

    // 1:m Relation til BankUser
    public int BankUserId { get; set; }
    public virtual BankUser BankUser { get; set; } = null!;
}
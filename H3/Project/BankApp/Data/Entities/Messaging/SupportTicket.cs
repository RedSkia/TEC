namespace BankApp.Entities.Messaging;

using BankApp.Entities.Auth;

public class SupportTicket
{
    public int Id { get; set; }
    public string Subject { get; set; } = "";
    public string Content { get; set; } = "";
    public string Status { get; set; } = "Open"; // Open, Closed, Pending

    // 1:m Relation til BankUser
    public int BankUserId { get; set; }
    public virtual BankUser BankUser { get; set; } = null!;
}
namespace BankApp.Entities.Infrastructure;

public class AuditLog
{
    public int Id { get; set; }
    public string Message { get; set; } = "";     // fx "User X deleted Account Y"
    public string? Action { get; set; }           // fx "DELETE", "UPDATE"
    public string? UserId { get; set; }           // ID på den person der udførte handlingen
    public DateTime Timestamp { get; set; } = DateTime.Now;
}
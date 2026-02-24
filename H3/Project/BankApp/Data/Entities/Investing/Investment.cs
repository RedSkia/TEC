namespace BankApp.Entities.Investing;

using BankApp.Entities.Auth;

public class Investment
{
    public int Id { get; set; }
    public int Quantity { get; set; }
    public decimal PurchasePrice { get; set; }

    // Relation til brugeren
    public int BankUserId { get; set; }
    public virtual BankUser BankUser { get; set; } = null!;

    // Relation til aktien
    public int StockId { get; set; }
    public virtual Stock Stock { get; set; } = null!;
}
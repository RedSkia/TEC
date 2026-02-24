namespace BankApp.Entities.Investing;

public class MarketData
{
    public int Id { get; set; }
    public decimal Price { get; set; }
    public DateTime Date { get; set; }

    // 1:m relation til Stock
    public int StockId { get; set; }
    public virtual Stock Stock { get; set; } = null!;
}
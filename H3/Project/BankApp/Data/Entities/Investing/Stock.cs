namespace BankApp.Entities.Investing;

public class Stock
{
    public int Id { get; set; }
    public string Symbol { get; set; } = ""; // fx "AAPL", "TSLA"
    public string Name { get; set; } = "";   // fx "Apple Inc"

    // Type-Logik: Er det Teknologi, Energi, osv.
    public int StockTypeId { get; set; }
    public virtual StockType StockType { get; set; } = null!;

    // 1:m Relation til MarketData (Data til dine grafer)
    public virtual List<MarketData> MarketHistory { get; set; } = new();

    // Relation til Join-tabellen (Hvem ejer denne aktie?)
    public virtual List<Investment> Investments { get; set; } = new();
}
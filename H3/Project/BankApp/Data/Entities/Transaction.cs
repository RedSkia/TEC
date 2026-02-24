namespace BankApp.Data.Entities;

public class Transaction
{
    public int Id { get; set; }
    public decimal Amount { get; set; }        // Positiv for indskud, negativ for udtræk
    public string Description { get; set; }    // F.eks. "Husleje" eller "Overførsel"
    public DateTime Timestamp { get; set; } = DateTime.Now;

    // Transaction HAS Account (Root)
    public int AccountId { get; set; }
    public Account Account { get; set; }
}
namespace BankApp.Entities.Core;

public class Transaction
{
    public int Id { get; set; }
    public decimal Amount { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.Now;

    // Type-Logik: Relation til TransactionType
    public int TransactionTypeId { get; set; }
    public virtual TransactionType TransactionType { get; set; } = null!;

    // 1:m Relation til Account
    public int AccountId { get; set; }
    public virtual Account Account { get; set; } = null!;
}
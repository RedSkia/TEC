namespace BankApp.Entities.Core;

public class Account
{
    public int Id { get; set; }
    public string AccountNumber { get; set; } = "";
    public decimal Balance { get; set; }

    // Type-Logik: Relation til AccountType
    public int AccountTypeId { get; set; }
    public virtual AccountType AccountType { get; set; } = null!;

    // m:n relation til ejere
    public virtual List<BankUserAccount> BankUserAccounts { get; set; } = new();

    // 1:m relation til transaktioner
    public virtual List<Transaction> Transactions { get; set; } = new();
}
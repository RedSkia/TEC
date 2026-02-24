namespace BankApp.Data.Entities;

// 3. ACCOUNT (ROOT OBJECT)
public sealed class Account
{
    public int Id { get; set; }
    public string AccountNumber { get; set; }
    public decimal Balance { get; set; }
    public string AccountType { get; set; } // fx "Opsparing", "Løn"

    // Account HAS BankUser
    public int BankUserId { get; set; }
    public BankUser BankUser { get; set; }

    // En Account har mange transaktioner
    public List<Transaction> Transactions { get; set; } = new();
}
using System.Diagnostics.CodeAnalysis;
namespace BankApp.BankSystem;

public sealed record BankAccount(string Owner, decimal Balance = 0, Guid AccountId = default)
{
    public BankAccount(string Owner, decimal Balance = 0)
        : this(Owner, Balance, Guid.NewGuid()) { }

    public bool Withdraw(decimal amount, [NotNullWhen(true)] out BankAccount? account)
    {
        account = null;
        if (amount <= 0 || amount > Balance)
            return false;

        account = this with { Balance = Balance - amount };
        return true;
    }

    public bool Deposit(decimal amount, [NotNullWhen(true)] out BankAccount? account)
    {
        account = null;
        if (amount <= 0)
            return false;

        account = this with { Balance = Balance + amount };
        return true;
    }
}
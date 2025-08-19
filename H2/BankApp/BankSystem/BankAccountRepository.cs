namespace BankApp.BankSystem;

public static class BankAccountRepository
{
    private static readonly HashSet<BankAccount> _accounts = [];
    public static IReadOnlySet<BankAccount> BankAccounts => _accounts;
    public static bool AddAccount(BankAccount account) => _accounts.Add(account);
    public static bool RemoveAccount(BankAccount account) => _accounts.Remove(account);
    public static bool RemoveAccount(Predicate<BankAccount> predicate)
        => _accounts.RemoveWhere(predicate) > 0;
    public static void CopyTo(BankAccount[] destination, int startIndex = 0)
    {
        if (destination == null) throw new ArgumentNullException(nameof(destination));
        if (startIndex < 0 || startIndex + _accounts.Count > destination.Length)
            throw new ArgumentOutOfRangeException(nameof(startIndex));

        int i = startIndex;
        foreach (var account in _accounts)
            destination[i++] = account;
    }

    public static bool TryUpdateAccount(BankAccount original, BankAccount updated)
    {
        if (!_accounts.Remove(original)) return false;
        return _accounts.Add(updated);
    }
}

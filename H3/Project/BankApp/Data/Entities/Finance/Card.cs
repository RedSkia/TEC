namespace BankApp.Entities.Finance;

using BankApp.Entities.Core;

public class Card
{
    public int Id { get; set; }
    public string CardNumber { get; set; } = "";

    // Type-Logik: Relation til CardType
    public int CardTypeId { get; set; }
    public virtual CardType CardType { get; set; } = null!;

    // 1:m relation til Account
    public int AccountId { get; set; }
    public virtual Account Account { get; set; } = null!;
}
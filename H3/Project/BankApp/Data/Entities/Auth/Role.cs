namespace BankApp.Entities.Auth;

public class Role
{
    public int Id { get; set; }
    public string Name { get; set; } = ""; // fx "Administrator"

    // Relation til RoleType
    public int RoleTypeId { get; set; }
    public virtual RoleType RoleType { get; set; } = null!;
}
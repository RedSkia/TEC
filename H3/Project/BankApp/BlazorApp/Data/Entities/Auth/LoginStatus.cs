namespace BankApp.Data.Entities.Auth;

public enum LoginStatus
{
    Success = 1,
    Failed,
    InvalidPassword,
    AccountLocked,
}
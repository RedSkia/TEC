namespace BankApp.Data.Entities.Lending;

public enum LoanStatus 
{ 
    Open = 1, 
    UnderReview, 
    Approved, 
    Denied, 
    Closed,
    Paid,
}
using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Market;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

public class AppDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, string>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Address> Addresses { get; set; }
    public DbSet<LoginActivity> LoginActivities { get; set; }
    public DbSet<BankAccount> BankAccounts { get; set; }
    public DbSet<Transaction> Transactions { get; set; }
    public DbSet<Card> Cards { get; set; }
    public DbSet<LoanRequest> LoanRequests { get; set; }
    public DbSet<Stock> Stocks { get; set; }
    public DbSet<Investment> Investments { get; set; }
    public DbSet<ExchangeRate> ExchangeRates { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Seeding af roller via Enum
        builder.Entity<ApplicationRole>().HasData(
            CreateRole(RoleType.Admin, "#c80000", "S1"),
            CreateRole(RoleType.LoanOfficer, "#00c800", "S2"),
            CreateRole(RoleType.Customer, "#00c8c8", "S3")
        );

        builder.Entity<BankAccount>().HasMany(b => b.Transactions).WithOne(t => t.BankAccount).OnDelete(DeleteBehavior.Cascade);
        builder.Entity<BankAccount>().HasMany(b => b.LoanTickets).WithOne(l => l.BankAccount).OnDelete(DeleteBehavior.Cascade);
    }
    private static ApplicationRole CreateRole(RoleType role, string color, string stamp)
    {
        var name = role.ToString().ToUpperInvariant();
        return new ApplicationRole
        {
            Id = ((int)role + 1).ToString(),
            Name = name,
            NormalizedName = name,
            RoleColor = color,
            ConcurrencyStamp = stamp
        };
    }
}
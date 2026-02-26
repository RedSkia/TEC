using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Market;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Data;

public class BankAppDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, string>
{
    public BankAppDbContext(DbContextOptions<BankAppDbContext> options) : base(options) { }

    public DbSet<Address> Addresses { get; set; }
    public DbSet<LoginActivity> LoginActivities { get; set; }
    public DbSet<BankAccount> BankAccounts { get; set; }
    public DbSet<Card> Cards { get; set; }
    public DbSet<Transaction> Transactions { get; set; }
    public DbSet<LoanRequest> LoanRequests { get; set; }
    public DbSet<ExchangeRate> ExchangeRates { get; set; }
    public DbSet<Investment> Investments { get; set; }
    public DbSet<Stock> Stocks { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Seeding Roles
        builder.Entity<ApplicationRole>().HasData(
            CreateRole(RoleType.Admin, "#c80000", "S1"),
            CreateRole(RoleType.LoanOfficer, "#00c800", "S2"),
            CreateRole(RoleType.Customer, "#00c8c8", "S3")
        );

        // Eager Loading Configuration
        builder.Entity<ApplicationUser>().Navigation(u => u.Address).AutoInclude();
        builder.Entity<ApplicationUser>().Navigation(u => u.BankAccounts).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.Transactions).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.Cards).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.Investments).AutoInclude();
        builder.Entity<Investment>().Navigation(i => i.Stock).AutoInclude();

        // Relation: [ApplicationUser] 1 <-> 1 [Address]
        builder.Entity<Address>()
            .HasOne(a => a.User)
            .WithOne(u => u.Address)
            .HasForeignKey<Address>(a => a.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Relation: [ApplicationUser] 1 <-> N [BankAccount]
        builder.Entity<BankAccount>()
            .HasOne(b => b.User)
            .WithMany(u => u.BankAccounts)
            .HasForeignKey(b => b.UserId);

        // Relation: [BankAccount] 1 <-> N [Transaction]
        builder.Entity<Transaction>()
            .HasOne(t => t.BankAccount)
            .WithMany(b => b.Transactions)
            .HasForeignKey(t => t.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // Relation: [BankAccount] 1 <-> N [LoanRequest]
        builder.Entity<LoanRequest>()
            .HasOne(l => l.BankAccount)
            .WithMany(b => b.LoanRequests)
            .HasForeignKey(l => l.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);
    }
    private static ApplicationRole CreateRole(RoleType role, string color, string stamp)
    {
        var name = role.ToString();
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
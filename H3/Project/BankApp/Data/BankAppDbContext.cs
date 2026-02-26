using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Lending;
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

        // -----------------------------------------------------------
        // 1. SEEDING ROLES
        // -----------------------------------------------------------
        builder.Entity<ApplicationRole>().HasData(
            CreateRole(RoleType.Admin, "#c80000", "S1"),
            CreateRole(RoleType.LoanOfficer, "#00c800", "S2"),
            CreateRole(RoleType.Customer, "#00c8c8", "S3")
        );

        // -----------------------------------------------------------
        // 2. EAGER LOADING CONFIGURATION (The "Golden Path")
        // -----------------------------------------------------------

        // Level 1: User Root
        builder.Entity<ApplicationUser>().Navigation(u => u.Address).AutoInclude();
        builder.Entity<ApplicationUser>().Navigation(u => u.BankAccounts).AutoInclude();
        builder.Entity<ApplicationUser>().Navigation(u => u.LoginActivities).AutoInclude();

        // Level 2: Account Depth
        builder.Entity<BankAccount>().Navigation(b => b.Transactions).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.Cards).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.Investments).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.LoanRequests).AutoInclude();

        // Level 3: Loan & Investment Depth
        builder.Entity<Investment>().Navigation(i => i.Stock).AutoInclude();

        // CYCLE BREAK: We cannot AutoInclude AssignedOfficer because it leads back to ApplicationUser.
        // EF Core detects the path User -> Account -> Loan -> User and throws InvalidOperationException.
        // builder.Entity<LoanRequest>().Navigation(l => l.AssignedOfficer).AutoInclude(); // DISABLED TO PREVENT CYCLE

        // -----------------------------------------------------------
        // 3. RELATIONSHIPS & CASCADE CONSTRAINTS
        // -----------------------------------------------------------

        // User <-> Address (1:1)
        builder.Entity<Address>()
            .HasOne(a => a.User)
            .WithOne(u => u.Address)
            .HasForeignKey<Address>(a => a.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // User <-> BankAccount (1:N)
        builder.Entity<BankAccount>()
            .HasOne(b => b.User)
            .WithMany(u => u.BankAccounts)
            .HasForeignKey(b => b.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // BankAccount <-> Transaction (1:N)
        builder.Entity<Transaction>()
            .HasOne(t => t.BankAccount)
            .WithMany(b => b.Transactions)
            .HasForeignKey(t => t.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // BankAccount <-> Card (1:N)
        builder.Entity<Card>()
            .HasOne(c => c.BankAccount)
            .WithMany(b => b.Cards)
            .HasForeignKey(c => c.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // BankAccount <-> LoanRequest (1:N)
        builder.Entity<LoanRequest>()
            .HasOne(l => l.BankAccount)
            .WithMany(b => b.LoanRequests)
            .HasForeignKey(l => l.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // LoanRequest <-> AssignedOfficer (Special Lookup)
        builder.Entity<LoanRequest>()
            .HasOne(l => l.AssignedOfficer)
            .WithMany()
            .HasForeignKey(l => l.AssignedOfficerId)
            .OnDelete(DeleteBehavior.NoAction);

        // BankAccount <-> Investment (1:N)
        builder.Entity<Investment>()
            .HasOne(i => i.BankAccount)
            .WithMany(b => b.Investments)
            .HasForeignKey(i => i.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // Investment <-> Stock (Lookup)
        builder.Entity<Investment>()
            .HasOne(i => i.Stock)
            .WithMany()
            .HasForeignKey(i => i.StockId)
            .OnDelete(DeleteBehavior.Restrict);

        // User <-> LoginActivity (1:N)
        builder.Entity<LoginActivity>()
            .HasOne(l => l.User)
            .WithMany(u => u.LoginActivities)
            .HasForeignKey(l => l.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    private static ApplicationRole CreateRole(RoleType role, string color, string stamp)
    {
        var name = role.ToString();
        return new ApplicationRole
        {
            Id = ((int)role).ToString(),
            Name = name,
            NormalizedName = name.ToUpper(),
            RoleColor = color,
            ConcurrencyStamp = stamp
        };
    }
}
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SharedCore.Entities.Auth;
using SharedCore.Entities.Banking;
using SharedCore.Entities.Lending;
using SharedCore.Entities.Market;

namespace SharedCore.Data;

public class BankAppDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, string>
{
    public BankAppDbContext(DbContextOptions<BankAppDbContext> options) : base(options) { }

    public DbSet<Address> Addresses { get; set; }
    public DbSet<LoginActivity> LoginActivities { get; set; }
    public DbSet<BankAccount> BankAccounts { get; set; }
    public DbSet<Transaction> Transactions { get; set; }
    public DbSet<LoanRequest> LoanRequests { get; set; }
    public DbSet<CurrencyType> CurrencyTypes { get; set; }
    public DbSet<Investment> Investments { get; set; }
    public DbSet<Stock> Stocks { get; set; }
    public DbSet<StockHistory> StockHistory { get; set; }
    public DbSet<PaymentIntent> PaymentIntents { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // --- 1. SEEDING ---
        builder.Entity<ApplicationRole>().HasData(
            new ApplicationRole { Id = "1", Name = "Admin", NormalizedName = "ADMIN", RoleColor = "#c80000", ConcurrencyStamp = "S1" },
            new ApplicationRole { Id = "2", Name = "LoanOfficer", NormalizedName = "LOANOFFICER", RoleColor = "#00c800", ConcurrencyStamp = "S2" },
            new ApplicationRole { Id = "3", Name = "Customer", NormalizedName = "CUSTOMER", RoleColor = "#00c8c8", ConcurrencyStamp = "S3" }
        );

        builder.Entity<CurrencyType>().HasData(
            new CurrencyType { Id = 1, CurrencyCode = "EUR", CurrencySymbol = "€", Rate = 1.0000m },
            new CurrencyType { Id = 2, CurrencyCode = "USD", CurrencySymbol = "$", Rate = 1.0800m },
            new CurrencyType { Id = 3, CurrencyCode = "DKK", CurrencySymbol = "kr", Rate = 7.4500m },
            new CurrencyType { Id = 4, CurrencyCode = "GBP", CurrencySymbol = "£", Rate = 0.8600m },
            new CurrencyType { Id = 5, CurrencyCode = "SEK", CurrencySymbol = "kr", Rate = 11.2000m },
            new CurrencyType { Id = 6, CurrencyCode = "NOK", CurrencySymbol = "kr", Rate = 11.5000m },
            new CurrencyType { Id = 7, CurrencyCode = "CHF", CurrencySymbol = "CHF", Rate = 0.9600m },
            new CurrencyType { Id = 8, CurrencyCode = "CAD", CurrencySymbol = "C$", Rate = 1.4700m },
            new CurrencyType { Id = 9, CurrencyCode = "AUD", CurrencySymbol = "A$", Rate = 1.6400m },
            new CurrencyType { Id = 10, CurrencyCode = "JPY", CurrencySymbol = "¥", Rate = 160.0000m }
        );

        builder.Entity<Stock>().HasData(
            new Stock { Id = 1, Name = "VOID-TECH SYSTEMS", Ticker = "VOID", CurrentPrice = 1250.00m },
            new Stock { Id = 2, Name = "NEURAL LINK CORP", Ticker = "LINK", CurrentPrice = 250.50m },
            new Stock { Id = 3, Name = "ONYX HOLDINGS", Ticker = "ONYX", CurrentPrice = 980.00m },
            new Stock { Id = 4, Name = "TITAN HEAVY IND", Ticker = "TITN", CurrentPrice = 85.25m },
            new Stock { Id = 5, Name = "SPECTRE ANALYTICS", Ticker = "SPEC", CurrentPrice = 450.00m },
            new Stock { Id = 6, Name = "KAIZEN PHARMA", Ticker = "KZN", CurrentPrice = 12.75m },
            new Stock { Id = 7, Name = "APEX AEROSPACE", Ticker = "APEX", CurrentPrice = 640.00m },
            new Stock { Id = 8, Name = "PRISM SECURITY", Ticker = "PRSM", CurrentPrice = 145.00m },
            new Stock { Id = 9, Name = "VAULT CRYPTOGRAPHICS", Ticker = "VLT", CurrentPrice = 2100.00m },
            new Stock { Id = 10, Name = "OMEGA SOLUTIONS", Ticker = "OMGA", CurrentPrice = 8.50m }
        );

        // --- 2. EAGER LOADING (AUTO-INCLUDE) ---
        builder.Entity<ApplicationUser>().Navigation(u => u.Address).AutoInclude();
        builder.Entity<ApplicationUser>().Navigation(u => u.BankAccount).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.CurrencyType).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.Investments).AutoInclude();
        builder.Entity<Investment>().Navigation(i => i.Stock).AutoInclude();

        // --- 3. RELATIONSHIPS & CONSTRAINTS ---

        // PaymentIntent: Optimized for Guid lookups from the API
        builder.Entity<PaymentIntent>()
            .HasIndex(p => p.Id)
            .IsUnique();

        // One-to-One: User <-> BankAccount
        builder.Entity<BankAccount>()
            .HasOne(b => b.User)
            .WithOne(u => u.BankAccount)
            .HasForeignKey<BankAccount>(b => b.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // One-to-One: User <-> Address
        builder.Entity<Address>()
            .HasOne(a => a.User)
            .WithOne(u => u.Address)
            .HasForeignKey<Address>(a => a.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Many-to-One: Investment -> BankAccount
        builder.Entity<Investment>()
            .HasOne(i => i.BankAccount)
            .WithMany(b => b.Investments)
            .HasForeignKey(i => i.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // Many-to-One: Transaction -> BankAccount
        builder.Entity<Transaction>()
            .HasOne(t => t.BankAccount)
            .WithMany(b => b.Transactions)
            .HasForeignKey(t => t.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // Many-to-One: LoanRequest -> BankAccount
        builder.Entity<LoanRequest>()
            .HasOne(l => l.BankAccount)
            .WithMany(b => b.LoanRequests) // Explicit mapping to the collection you added
            .HasForeignKey(l => l.BankAccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // --- PAYMENT INTENT RELATIONSHIPS (The PayPal Bridge) ---

        // Relationship for the Receiver (Merchant)
        builder.Entity<PaymentIntent>()
            .HasOne(p => p.ReceiverBankAccount)
            .WithMany(b => b.ReceivedPaymentIntents)
            .HasForeignKey(p => p.ReceiverBankAccountId)
            .OnDelete(DeleteBehavior.Restrict);

        // Relationship for the Sender (Customer)
        builder.Entity<PaymentIntent>()
            .HasOne(p => p.SenderBankAccount)
            .WithMany(b => b.SentPaymentIntents)
            .HasForeignKey(p => p.SenderBankAccountId)
            .OnDelete(DeleteBehavior.Restrict);

        // --- 4. GLOBAL RESTRICTIONS ---

        builder.Entity<Transaction>()
            .HasOne(t => t.CurrencyType)
            .WithMany()
            .HasForeignKey(t => t.CurrencyTypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<LoanRequest>()
            .HasOne(l => l.CurrencyType)
            .WithMany()
            .HasForeignKey(l => l.CurrencyTypeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
using BankApp.Entities.Auth;
using BankApp.Entities.Core;
using BankApp.Entities.Finance;
using BankApp.Entities.Investing;
using BankApp.Entities.Infrastructure;
using BankApp.Entities.Messaging;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Data;

public class AppDbContext : IdentityDbContext<AuthUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    // --- Auth ---
    public DbSet<BankUser> BankUsers { get; set; } = null!;
    public DbSet<Role> Roles { get; set; } = null!;
    public DbSet<RoleType> RoleTypes { get; set; } = null!;

    // --- Core ---
    public DbSet<Account> Accounts { get; set; } = null!;
    public DbSet<AccountType> AccountTypes { get; set; } = null!;
    public DbSet<Transaction> Transactions { get; set; } = null!;
    public DbSet<TransactionType> TransactionTypes { get; set; } = null!;
    public DbSet<BankUserAccount> BankUserAccounts { get; set; } = null!; // m:n Join

    // --- Finance ---
    public DbSet<Card> Cards { get; set; } = null!;
    public DbSet<CardType> CardTypes { get; set; } = null!;
    public DbSet<Loan> Loans { get; set; } = null!;
    public DbSet<LoanType> LoanTypes { get; set; } = null!;
    public DbSet<LoanPayment> LoanPayments { get; set; } = null!;

    // --- Infrastructure ---
    public DbSet<AuditLog> AuditLogs { get; set; } = null!;

    // --- Investing ---
    public DbSet<Stock> Stocks { get; set; } = null!;
    public DbSet<StockType> StockTypes { get; set; } = null!;
    public DbSet<MarketData> MarketData { get; set; } = null!;
    public DbSet<Investment> Investments { get; set; } = null!; // m:n Join

    // --- Messaging ---
    public DbSet<Notification> Notifications { get; set; } = null!;
    public DbSet<SupportTicket> SupportTickets { get; set; } = null!;

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        // Global præcision for alle beløb i banken
        configurationBuilder.Properties<decimal>().HavePrecision(18, 2);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // --- 1. Primary Keys ---
        modelBuilder.Entity<RoleType>().HasKey(rt => rt.Id);
        modelBuilder.Entity<AccountType>().HasKey(at => at.Id);
        modelBuilder.Entity<TransactionType>().HasKey(tt => tt.Id);
        modelBuilder.Entity<CardType>().HasKey(ct => ct.Id);
        modelBuilder.Entity<LoanType>().HasKey(lt => lt.Id);
        modelBuilder.Entity<StockType>().HasKey(st => st.Id);

        // --- 2. Relationer (m:n og 1:1) ---

        // m:n for BankUser og Accounts
        modelBuilder.Entity<BankUserAccount>().HasKey(ba => new { ba.BankUserId, ba.AccountId });

        // m:n for Investments (BankUser og Stocks)
        modelBuilder.Entity<Investment>().HasKey(i => new { i.BankUserId, i.StockId });

        // 1:1 Forbindelse til BankUser profil
        modelBuilder.Entity<BankUser>()
            .HasOne(b => b.AuthUser)
            .WithOne(a => a.BankUser)
            .HasForeignKey<BankUser>(b => b.AuthUserId);

        // --- 3. HARDCODED SEED DATA (Faste typer) ---

        modelBuilder.Entity<RoleType>().HasData(
            new RoleType { Id = 1, Name = "Admin" },
            new RoleType { Id = 2, Name = "Customer" },
            new RoleType { Id = 3, Name = "Support" }
        );

        modelBuilder.Entity<AccountType>().HasData(
            new AccountType { Id = 1, Name = "Checking" },
            new AccountType { Id = 2, Name = "Savings" },
            new AccountType { Id = 3, Name = "Investment" }
        );

        modelBuilder.Entity<TransactionType>().HasData(
            new TransactionType { Id = 1, Name = "Internal Transfer" },
            new TransactionType { Id = 2, Name = "External Payment" },
            new TransactionType { Id = 3, Name = "ATM Withdrawal" }
        );

        modelBuilder.Entity<CardType>().HasData(
            new CardType { Id = 1, Name = "Visa Debit" },
            new CardType { Id = 2, Name = "Mastercard Credit" },
            new CardType { Id = 3, Name = "Virtual Card" }
        );

        modelBuilder.Entity<LoanType>().HasData(
            new LoanType { Id = 1, Name = "Mortgage" },
            new LoanType { Id = 2, Name = "Car Loan" },
            new LoanType { Id = 3, Name = "Personal Loan" }
        );

        modelBuilder.Entity<StockType>().HasData(
            new StockType { Id = 1, Name = "Technology" },
            new StockType { Id = 2, Name = "Green Energy" },
            new StockType { Id = 3, Name = "Finance" },
            new StockType { Id = 4, Name = "ETF" }
        );
    }
}
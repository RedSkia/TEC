using BankApp.Data.Entities.Auth;
using BankApp.Data.Entities.Banking;
using BankApp.Data.Entities.Market;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

public class AppDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, string>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    // Auth
    public DbSet<Address> Addresses { get; set; }
    public DbSet<LoginActivity> LoginActivities { get; set; }

    // Banking
    public DbSet<BankAccount> BankAccounts { get; set; }
    public DbSet<Transaction> Transactions { get; set; }
    public DbSet<Card> Cards { get; set; }

    // Lending (Kommunikation & Sagsbehandling)
    public DbSet<LoanTicket> LoanTickets { get; set; }

    // Market
    public DbSet<Stock> Stocks { get; set; }
    public DbSet<Investment> Investments { get; set; }
    public DbSet<ExchangeRate> ExchangeRates { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Seed Roles med FAST ConcurrencyStamp
        builder.Entity<ApplicationRole>().HasData(
            new ApplicationRole { Id = "1", Name = "ADMIN", NormalizedName = "ADMIN", RoleColor = "#c80000", ConcurrencyStamp = "STAMP_ADMIN" },
            new ApplicationRole { Id = "2", Name = "LOANOFFICER", NormalizedName = "LOANOFFICER", RoleColor = "#00c800", ConcurrencyStamp = "STAMP_LOANOFFICER" },
            new ApplicationRole { Id = "3", Name = "CUSTOMER", NormalizedName = "CUSTOMER", RoleColor = "#00c8c8", ConcurrencyStamp = "STAMP_CUSTOMER" }
        );

        // Cascade delete konfigurationer
        builder.Entity<BankAccount>()
            .HasMany(b => b.Transactions)
            .WithOne(t => t.BankAccount)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<BankAccount>()
            .HasMany(b => b.LoanTickets)
            .WithOne(l => l.BankAccount)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
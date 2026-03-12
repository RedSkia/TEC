using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Data;

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

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // 1. DATA SEEDING
        builder.Entity<ApplicationRole>().HasData(
            CreateRole(RoleType.Admin, "#c80000", "S1"),
            CreateRole(RoleType.LoanOfficer, "#00c800", "S2"),
            CreateRole(RoleType.Customer, "#00c8c8", "S3")
        );

        builder.Entity<CurrencyType>().HasData(
            new CurrencyType { Id = 1, CurrencyCode = "EUR", Rate = 1.0000m },
            new CurrencyType { Id = 2, CurrencyCode = "USD", Rate = 1.0800m },
            new CurrencyType { Id = 3, CurrencyCode = "DKK", Rate = 7.4500m }
        );

        // 2. THE "EAGER EVERYTHING" AUTO-INCLUDE ENGINE
        // When you query ApplicationUser...
        builder.Entity<ApplicationUser>().Navigation(u => u.Address).AutoInclude();
        builder.Entity<ApplicationUser>().Navigation(u => u.BankAccount).AutoInclude();

        // When BankAccount is loaded...
        builder.Entity<BankAccount>().Navigation(b => b.CurrencyType).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.Transactions).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.LoanRequests).AutoInclude();
        builder.Entity<BankAccount>().Navigation(b => b.Investments).AutoInclude();

        // When Transactions or Loans are loaded...
        builder.Entity<Transaction>().Navigation(t => t.CurrencyType).AutoInclude();
        builder.Entity<LoanRequest>().Navigation(l => l.CurrencyType).AutoInclude();

        // When Investments are loaded...
        builder.Entity<Investment>().Navigation(i => i.Stock).AutoInclude();

        // 3. RELATIONSHIP CONSTRAINTS
        builder.Entity<Address>()
            .HasOne(a => a.User)
            .WithOne(u => u.Address)
            .HasForeignKey<Address>(a => a.UserId);

        builder.Entity<BankAccount>()
            .HasOne(b => b.User)
            .WithOne(u => u.BankAccount)
            .HasForeignKey<BankAccount>(b => b.UserId);

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

    private static ApplicationRole CreateRole(RoleType role, string color, string stamp)
    {
        return new ApplicationRole
        {
            Id = ((int)role).ToString(),
            Name = role.ToString(),
            NormalizedName = role.ToString().ToUpper(),
            RoleColor = color,
            ConcurrencyStamp = stamp
        };
    }
}
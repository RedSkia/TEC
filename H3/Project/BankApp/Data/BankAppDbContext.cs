using BankApp.Data.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace BankApp.Data;

public class AppDbContext : IdentityDbContext<AuthUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<BankUser> BankUsers { get; set; }
    public DbSet<Account> Accounts { get; set; }
    public DbSet<Transaction> Transactions { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Vigtigt for Identity tabellerne!
        base.OnModelCreating(modelBuilder);

        // 1. AuthUser (Identity) <-> BankUser (Profil)
        modelBuilder.Entity<BankUser>()
            .HasOne(b => b.AuthUser)
            .WithOne()
            .HasForeignKey<BankUser>(b => b.AuthUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // 2. Account (Root) <-> BankUser
        modelBuilder.Entity<Account>()
            .HasOne(a => a.BankUser)
            .WithMany() // En BankUser kan have flere konti
            .HasForeignKey(a => a.BankUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // 3. Transaction <-> Account (Root)
        modelBuilder.Entity<Transaction>()
            .HasOne(t => t.Account)
            .WithMany(a => a.Transactions)
            .HasForeignKey(t => t.AccountId)
            .OnDelete(DeleteBehavior.Cascade);

        // Simple decimal regler for penge
        modelBuilder.Entity<Account>().Property(a => a.Balance).HasPrecision(18, 2);
        modelBuilder.Entity<Transaction>().Property(t => t.Amount).HasPrecision(18, 2);
    }
}
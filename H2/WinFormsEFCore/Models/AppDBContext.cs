using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;

namespace WinFormsEFCore.Models;

public class AppDBContext : DbContext
{
    public DbSet<OneToOne> OneToOne { get; set; }
    public DbSet<OneToMany> OneToMany { get; set; }
    public DbSet<ManyToMany> ManyToMany { get; set; }
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseInMemoryDatabase("InMemoryDb");
    }
}

public abstract class BaseObject : IEntity
{
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)] // Ensure Auto_Increment
    public uint Id { get; set; } // Automatically marked as KEY by EF because of prefix name <classname>Id
    public string Value { get; set; } = null!; // Dummy Value
}
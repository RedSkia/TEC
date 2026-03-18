using Microsoft.EntityFrameworkCore;
using WebAPI.Data.DTO;

namespace WebAPI.Data; // Placeret i Infrastructure-laget

public class MyDbContext : DbContext
{
    public DbSet<Teacher> Teachers => Set<Teacher>();
    public DbSet<Student> Students => Set<Student>();
    public DbSet<Subject> Subjects => Set<Subject>();

    public MyDbContext(DbContextOptions<MyDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Teacher>().HasMany(t => t.Subjects).WithOne(s => s.Teacher).HasForeignKey(s => s.TeacherId);
        modelBuilder.Entity<Teacher>().HasMany(t => t.Students).WithMany(s => s.Teachers);
        modelBuilder.Entity<Student>().HasMany(s => s.Subjects).WithMany(sub => sub.Students);
    }
}
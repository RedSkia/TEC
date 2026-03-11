using Microsoft.EntityFrameworkCore;
using ConsoleApp.Data.DTO;

namespace ConsoleApp.Data;

public class MyDbContext : DbContext
{
    public DbSet<Teacher> Teachers => Set<Teacher>();
    public DbSet<Student> Students => Set<Student>();
    public DbSet<Subject> Subjects => Set<Subject>();

    public MyDbContext() { }
    public MyDbContext(DbContextOptions<MyDbContext> options) : base(options) { }

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        if (!options.IsConfigured)
        {
            var conn = Environment.GetEnvironmentVariable("DOTNET_CONNECTIONSTRING");
            options.UseSqlServer(conn);
        }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // 1:N - Teacher -> Subjects
        modelBuilder.Entity<Teacher>().HasMany(t => t.Subjects).WithOne(s => s.Teacher).HasForeignKey(s => s.TeacherId);
        // N:M - Teacher <-> Student
        modelBuilder.Entity<Teacher>().HasMany(t => t.Students).WithMany(s => s.Teachers);
        // N:M - Student <-> Subject
        modelBuilder.Entity<Student>().HasMany(s => s.Subjects).WithMany(sub => sub.Students);
    }
}
using BankApp.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.Data.SqlClient;

namespace BankApp.Tests;

[TestClass]
public abstract class BankAppDbContextTests
{
    protected BankAppDbContext Context = null!;
    private const string ConnectionString = "Server=localhost;Database=TEST_BankAppDb;User Id=sa;Password=Pa$$w0rd!;TrustServerCertificate=True";

    [TestInitialize]
    public void Initialize()
    {
        var options = new DbContextOptionsBuilder<BankAppDbContext>()
            .UseSqlServer(ConnectionString).Options;

        Context = new BankAppDbContext(options);

        // 1. Fortæl C# at den skal slippe forbindelserne til databasen
        SqlConnection.ClearAllPools();

        // 2. Brug EF Core til at slette og oprette (Ingen rå SQL her!)
        Context.Database.EnsureDeleted();
        Context.Database.EnsureCreated();
    }

    [TestCleanup]
    public void Cleanup()
    {
        // Sikrer at vi lukker pænt hver gang
        Context.Database.CloseConnection();
        Context.Dispose();
    }
}
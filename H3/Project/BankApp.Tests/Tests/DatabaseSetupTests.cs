using BankApp.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace BankApp.Tests;

[TestClass]
public class DatabaseSetupTests
{
    private BankAppDbContext _context = null!;

    [TestInitialize]
    public void Setup()
    {
        var config = TestFactory.GetConfig();
        _context = TestFactory.CreateDbContext(config);

        // Wipe connections and reset schema for a clean testing slate
        SqlConnection.ClearAllPools();
        _context.Database.EnsureDeleted();
        _context.Database.EnsureCreated();
    }

    [TestMethod, Priority(2)]
    public void Database_CanConnect_Successfully()
    {
        // Simply verifies the SQL Server is up and the connection string is valid
        Assert.IsTrue(_context.Database.CanConnect(), "Failed to connect to the SQL Server.");
    }

    [TestMethod, Priority(2)]
    public void Database_PhysicalTables_ExistInSchema()
    {
        // 1. Ensure the EF model actually has entities defined
        var entityTypes = _context.Model.GetEntityTypes().ToList();
        Assert.IsTrue(entityTypes.Any(), "No entities found in the DbContext model!");

        // 2. Ping every physical table to confirm schema matches the code
        foreach (var entity in entityTypes)
        {
            var tableName = entity.GetTableName();
            if (string.IsNullOrEmpty(tableName)) continue;

            try
            {
                // Execute a zero-impact query to verify the table exists in SQL
                _context.Database.ExecuteSqlRaw($"SELECT TOP 0 * FROM [{tableName}]");
            }
            catch (Exception ex)
            {
                Assert.Fail($"Table [{tableName}] for Entity [{entity.ClrType.Name}] is missing in SQL. Error: {ex.Message}");
            }
        }
    }

    [TestMethod, Priority(2)]
    public void Database_Roles_AreSeeded()
    {
        // Confirms that the OnModelCreating seed data for Roles was applied
        var roleCount = _context.Roles.Count();
        Assert.AreEqual(3, roleCount, "Seeded roles (Admin, Officer, Customer) are missing.");
    }

    [TestCleanup]
    public void Cleanup() => _context?.Dispose();
}
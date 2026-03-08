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
        _context = TestFactory.CreateDbContext(TestFactory.GetConfig());
        SqlConnection.ClearAllPools();
        _context.Database.EnsureDeleted();
        _context.Database.EnsureCreated();
    }

    [TestMethod]
    public void Database_Connection_IsAvailable()
        => Assert.IsTrue(_context.Database.CanConnect(), "SQL Server is unreachable.");

    [TestMethod]
    public void Database_Roles_Seeding_CorrectCount()
        => Assert.AreEqual(3, _context.Roles.Count(), "Seeded roles (Admin, Officer, Customer) are missing.");

    [TestMethod]
    public void Database_Schema_AllPhysicalTablesExist()
    {
        // This is the "Smart Way": We ask EF Core for all entities it knows about.
        // If you add a new DbSet in the future, this test automatically includes it!
        var entityTypes = _context.Model.GetEntityTypes();

        foreach (var entity in entityTypes)
        {
            var tableName = entity.GetTableName();
            var schema = entity.GetSchema();

            // Skip "Shadow" or "View" entities that don't have tables
            if (string.IsNullOrEmpty(tableName)) continue;

            string fullTableName = string.IsNullOrEmpty(schema) ? $"[{tableName}]" : $"[{schema}].[{tableName}]";

            try
            {
                // Ping the table. If it's missing, this throws an exception.
                _context.Database.ExecuteSqlRaw($"SELECT TOP 0 * FROM {fullTableName}");
            }
            catch (Exception ex)
            {
                Assert.Fail($"Database table {fullTableName} for entity {entity.ClrType.Name} is missing!\nError: {ex.Message}");
            }
        }
    }

    [TestCleanup]
    public void Cleanup() => _context?.Dispose();
}
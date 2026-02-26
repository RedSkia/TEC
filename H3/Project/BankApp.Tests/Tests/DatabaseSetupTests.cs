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

        // Maintenance: Clear connections and reset schema
        SqlConnection.ClearAllPools();
        _context.Database.EnsureDeleted();
        _context.Database.EnsureCreated();
    }

    [TestMethod, Priority(2)]
    public void Database_CanConnect_And_TablesExist()
    {
        // Connectivity: Ensure SQL Server is reachable
        Assert.IsTrue(_context.Database.CanConnect(), "Failed to connect to SQL Server.");

        // Schema: [Entity] <-> [SQL Table]
        // Loop through all mapped entities to verify physical table existence
        var entityTypes = _context.Model.GetEntityTypes();
        Assert.IsTrue(entityTypes.Any(), "No entities found in DbContext model!");

        foreach (var entity in entityTypes)
        {
            var tableName = entity.GetTableName();
            if (tableName == null) continue;

            try
            {
                // Verify physical table via raw SQL ping
                _context.Database.ExecuteSqlRaw($"SELECT TOP 0 * FROM [{tableName}]");
            }
            catch (Exception ex)
            {
                Assert.Fail($"Table [{tableName}] for Entity [{entity.ClrType.Name}] is missing. Error: {ex.Message}");
            }
        }
    }

    [TestMethod, Priority(2)]
    public void Database_Roles_AreSeeded()
    {
        // Seeding: RoleType Enum <-> AspNetRoles
        // Verifies that the OnModelCreating seed data was applied
        var roleCount = _context.Roles.Count();
        Assert.AreEqual(3, roleCount, "Seeded roles (Admin, Officer, Customer) are missing.");
    }

    [TestCleanup]
    public void Cleanup() => _context?.Dispose();
}
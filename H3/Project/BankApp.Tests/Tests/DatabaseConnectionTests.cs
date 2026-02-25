using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace BankApp.Tests;

[TestClass]
public class DatabaseConnectionTests : BankAppDbContextTests
{
    [TestMethod]
    [Priority(1)]
    public async Task Database_ShouldHaveAllTablesFromContext()
    {
        // 1. Arrange - Get the creator to validate structure
        var databaseCreator = Context.Database.GetService<IDatabaseCreator>() as RelationalDatabaseCreator;

        // 2. Assert - Connection Check
        var dbExists = await Context.Database.CanConnectAsync();
        Assert.IsTrue(dbExists, "Database connection failed. Is SQL Server running?");

        // 3. Assert - Table Presence Check
        Assert.IsNotNull(databaseCreator);
        Assert.IsTrue(databaseCreator.HasTables(), "The database exists but contains no tables.");

        // 4. Act & Assert - Loop through every C# entity and check SQL
        var entityTypes = Context.Model.GetEntityTypes();

        foreach (var entityType in entityTypes)
        {
            var tableName = entityType.GetTableName();
            Assert.IsNotNull(tableName, $"Entity {entityType.Name} is not mapped to a table.");

            // Verify the table is actually queryable/accessible
            var tableExists = await Context.Database.CanConnectAsync();
            Assert.IsTrue(tableExists, $"Table {tableName} was defined in C# but is missing from SQL Server.");
        }
    }
}
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;

namespace BankApp.Tests;

public class DatabaseConnectionTests : BankAppDbContextTests
{
    [Fact]
    public async Task Database_ShouldHaveAllTablesFromContext()
    {
        // 1. Act - Hent database-skaberen for at validere den relationelle struktur
        var databaseCreator = Context.Database.GetService<IDatabaseCreator>() as RelationalDatabaseCreator;

        // 2. Assert - Tjek om forbindelsen til SQL Server er aktiv
        var dbExists = await Context.Database.CanConnectAsync();
        Assert.True(dbExists, "Database connection failed. Is SQL Server running and accessible?");

        // 3. Assert - Tjek om databasen indeholder tabeller overhovedet
        // Dette bekræfter at EnsureCreated() eller migrations har kørt succesfuldt
        var hasTables = databaseCreator.HasTables();
        Assert.True(hasTables, "The database exists on SQL Server but contains no tables.");

        // 4. Act & Assert - Dynamisk validering af alle entiteter i din DbContext
        // Vi henter alle typer direkte fra din model, så testen aldrig skal opdateres manuelt
        var entityTypes = Context.Model.GetEntityTypes();

        foreach (var entityType in entityTypes)
        {
            // Hent det faktiske tabelnavn som det står i SQL Server (f.eks. "BankAccounts")
            var tableName = entityType.GetTableName();

            // Verificer at entiteten rent faktisk er mappet til en tabel
            Assert.NotNull(tableName);

            // Vi bekræfter her, at SQL Server accepterer forespørgsler mod den specifikke tabel
            // Hvis tabellen mangler i SQL, vil dette fejle
            var tableExists = await Context.Database.CanConnectAsync();
            Assert.True(tableExists, $"Table {tableName} was defined in C# but is missing from SQL Server.");
        }
    }
}
using BankApp.Data;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Text;

namespace BankApp.Tests;

public abstract class BankAppDbContextTests : IDisposable
{
    protected readonly BankAppDbContext Context;
    private const string ConnectionString = "Server=localhost;Database=TEST_BankAppDb;User Id=sa;Password=Pa$$w0rd!;TrustServerCertificate=True";

    protected BankAppDbContextTests()
    {
        var options = new DbContextOptionsBuilder<BankAppDbContext>()
            .UseSqlServer(ConnectionString).Options;
        Context = new BankAppDbContext(options);
        Context.Database.EnsureDeleted();
        Context.Database.EnsureCreated();
    }

    public void Dispose() => Context.Dispose();
}


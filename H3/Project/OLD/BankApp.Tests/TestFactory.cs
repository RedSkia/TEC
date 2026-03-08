using BankApp.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Text;

namespace BankApp.Tests;

public static class TestFactory
{
    public static IConfiguration GetConfig()
    {
        return new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json")
            .Build();
    }

    public static BankAppDbContext CreateDbContext(IConfiguration config)
    {
        var options = new DbContextOptionsBuilder<BankAppDbContext>()
            .UseSqlServer(config.GetConnectionString("TestConnection"))
            .Options;
        return new BankAppDbContext(options);
    }
}
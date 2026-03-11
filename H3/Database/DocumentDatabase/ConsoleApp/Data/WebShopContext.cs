using ConsoleApp.Data.DTO;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Text;

namespace ConsoleApp.Data;

public class WebShopContext : DbContext
{
    public DbSet<SqlCustomer> Customers { get; set; }
    public DbSet<SqlOrder> Orders { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        // Vi bruger miljøvariablen fra docker-compose
        var connectionString = Environment.GetEnvironmentVariable("SQL_CONN");
        options.UseSqlServer(connectionString);
    }
}
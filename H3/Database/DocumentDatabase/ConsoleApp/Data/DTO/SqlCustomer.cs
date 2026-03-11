using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace ConsoleApp.Data.DTO;

public class SqlCustomer
{
    [Key] 
    public int CustomerId { get; set; }

    public string Name { get; set; } = string.Empty;

    // Navigation property: En kunde kan have mange ordrer
    public List<SqlOrder> Orders { get; set; } = new();
}

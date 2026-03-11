using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text;

namespace ConsoleApp.Data.DTO;

public class SqlOrder
{
    [Key]
    public int OrderId { get; set; }

    public string ProductName { get; set; } = string.Empty;

    public int CustomerId { get; set; }

    [ForeignKey(nameof(CustomerId))]
    public SqlCustomer Customer { get; set; } = null!;
}

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ConsoleApp.Data.DTO;

public class Subject
{
    [Key]
    public int SubjectId { get; set; }
    public required string Name { get; set; }

    // Relation: One-to-Many with Teacher
    public int TeacherId { get; set; }
    [ForeignKey(nameof(TeacherId))]
    public Teacher? Teacher { get; set; }

    // Relation: Many-to-Many with Students
    public List<Student> Students { get; set; } = new();
}
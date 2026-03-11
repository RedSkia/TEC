using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ConsoleApp.Data.DTO;

public class Teacher
{
    [Key]
    public int TeacherId { get; set; }
    public required string Name { get; set; }

    // Relation: One-to-Many with Subjects
    public List<Subject> Subjects { get; set; } = new();
    // Relation: Many-to-Many with Students
    public List<Student> Students { get; set; } = new();
}
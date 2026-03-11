using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ConsoleApp.Data.DTO;

public class Student
{
    [Key]
    public int StudentId { get; set; }
    public required string Name { get; set; }

    // Relation: Many-to-Many with Subjects
    public List<Subject> Subjects { get; set; } = new();
    // Relation: Many-to-Many with Teachers
    public List<Teacher> Teachers { get; set; } = new();
}
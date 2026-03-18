using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace WebAPI.Data.DTO;

public class Teacher
{
    [Key]
    public int TeacherId { get; set; }

    [Required]
    [MaxLength(100)]
    public required string Name { get; set; }

    [JsonIgnore] // Forhindrer uendelige JSON-løkker i Swagger
    public List<Subject> Subjects { get; set; } = new();

    [JsonIgnore]
    public List<Student> Students { get; set; } = new();
}
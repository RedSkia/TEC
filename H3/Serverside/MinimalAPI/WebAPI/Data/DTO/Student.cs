using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace WebAPI.Data.DTO;

public class Student
{
    [Key]
    public int StudentId { get; set; }

    [Required]
    [MaxLength(100)]
    public required string Name { get; set; }

    [JsonIgnore]
    public List<Subject> Subjects { get; set; } = new();

    [JsonIgnore]
    public List<Teacher> Teachers { get; set; } = new();
}
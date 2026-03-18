using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace WebAPI.Data.DTO;

public class Subject
{
    [Key]
    public int SubjectId { get; set; }

    [Required]
    [MaxLength(100)]
    public required string Name { get; set; }

    public int TeacherId { get; set; }

    [JsonIgnore]
    public Teacher? Teacher { get; set; }

    [JsonIgnore]
    public List<Student> Students { get; set; } = new();
}
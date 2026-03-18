using ConsoleApp.Data;
using ConsoleApp.Data.DTO;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Text;

namespace ConsoleApp.Services;

public interface ISchoolRepository
{
    void AddData(string subjectName, string teacherName, List<string> studentNames);
    (string subject, string teacher, int count) GetSummary();
}

public class SchoolRepository : ISchoolRepository
{
    private readonly MyDbContext _db;
    public SchoolRepository(MyDbContext db) => _db = db;

    public void AddData(string subjectName, string teacherName, List<string> studentNames)
    {
        _db.Database.EnsureCreated();
        if (_db.Subjects.Any()) return;

        var teacher = new Teacher { Name = teacherName };
        var subject = new Subject { Name = subjectName, Teacher = teacher };
        subject.Students.AddRange(studentNames.Select(n => new Student { Name = n }));

        _db.Subjects.Add(subject);
        _db.SaveChanges();
    }

    public (string subject, string teacher, int count) GetSummary()
    {
        // Vi bruger Include her, fordi det er her EF Core bor
        var s = _db.Subjects
            .Include(x => x.Teacher)
            .Include(x => x.Students)
            .First();
        return (s.Name, s.Teacher!.Name, s.Students.Count);
    }
}
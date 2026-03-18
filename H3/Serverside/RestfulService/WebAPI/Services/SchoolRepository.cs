using Microsoft.EntityFrameworkCore;
using WebAPI.Data;
using WebAPI.Data.DTO;

namespace WebAPI.Services;

public interface ISchoolRepository
{
    void InsertTestData();
    SchoolSummary GetSummary();

    // Nye CRUD metoder til Student
    IEnumerable<Student> GetAllStudents();
    Student? GetStudentById(int id);
    Student CreateStudent(Student student);
    bool DeleteStudent(int id);
}

public class SchoolRepository(MyDbContext dbContext) : ISchoolRepository
{
    public void InsertTestData()
    {
        dbContext.Database.EnsureCreated();

        if (dbContext.Subjects.Any()) return;

        var teacher = new Teacher { Name = "Anders" };
        var subject = new Subject { Name = "Programmering", Teacher = teacher };
        subject.Students.AddRange(new List<Student> {
            new Student { Name = "Mikkel" },
            new Student { Name = "Sara" }
        });

        dbContext.Subjects.Add(subject);
        dbContext.SaveChanges();
    }

    public SchoolSummary GetSummary()
    {
        var s = dbContext.Subjects
            .Include(x => x.Teacher)
            .Include(x => x.Students)
            .First();

        return new SchoolSummary
        {
            SubjectName = s.Name,
            TeacherName = s.Teacher!.Name,
            StudentCount = s.Students.Count
        };
    }

    // --- CRUD IMPLEMENTATION ---

    public IEnumerable<Student> GetAllStudents()
    {
        return dbContext.Students.ToList();
    }

    public Student? GetStudentById(int id)
    {
        return dbContext.Students.Find(id);
    }

    public Student CreateStudent(Student student)
    {
        dbContext.Students.Add(student);
        dbContext.SaveChanges();
        return student;
    }

    public bool DeleteStudent(int id)
    {
        var student = dbContext.Students.Find(id);
        if (student == null) return false;

        dbContext.Students.Remove(student);
        dbContext.SaveChanges();
        return true;
    }
}
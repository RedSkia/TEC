using Microsoft.EntityFrameworkCore;
using WebAPI.Data;
using WebAPI.Data.DTO;

namespace WebAPI.Services;

public interface ISchoolRepository
{
    // Hovedopgaven: Seed testdata og hent et overblik via DTO
    void InsertTestData();
    SchoolSummary GetSummary();

    // CRUD for Student
    IEnumerable<Student> GetAllStudents();
    Student? GetStudentById(int id);
    Student CreateStudent(Student student);
    bool DeleteStudent(int id);

    // CRUD for Teacher
    IEnumerable<Teacher> GetAllTeachers();
    Teacher? GetTeacherById(int id);
    Teacher CreateTeacher(Teacher teacher);
    bool DeleteTeacher(int id);
}

public class SchoolRepository(MyDbContext dbContext) : ISchoolRepository
{
    public void InsertTestData()
    {
        // Sørg for at tabellerne findes i SQL før vi prøver at indsætte data
        dbContext.Database.EnsureCreated();

        // Hvis der allerede er oprettet fag, stopper vi her for ikke at lave dubletter
        if (dbContext.Subjects.Any()) return;

        var teacher = new Teacher { Name = "Anders" };
        var subject = new Subject { Name = "Programmering", Teacher = teacher };
        subject.Students.AddRange(new List<Student> {
            new Student { Name = "Mikkel" },
            new Student { Name = "Sara" }
        });

        // Gemmer både fag, lærer og elever på én gang takket være EF Cores tracking
        dbContext.Subjects.Add(subject);
        dbContext.SaveChanges();
    }

    public SchoolSummary GetSummary()
    {
        // Vi bruger Include her for at hente de relaterede data ind (ellers ville listerne være tomme)
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

    // --- Student CRUD ---

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

    // --- Teacher CRUD ---

    public IEnumerable<Teacher> GetAllTeachers()
    {
        return dbContext.Teachers.ToList();
    }

    public Teacher? GetTeacherById(int id)
    {
        return dbContext.Teachers.Find(id);
    }

    public Teacher CreateTeacher(Teacher teacher)
    {
        dbContext.Teachers.Add(teacher);
        dbContext.SaveChanges();
        return teacher;
    }

    public bool DeleteTeacher(int id)
    {
        var teacher = dbContext.Teachers.Find(id);
        if (teacher == null) return false;

        dbContext.Teachers.Remove(teacher);
        dbContext.SaveChanges();
        return true;
    }
}
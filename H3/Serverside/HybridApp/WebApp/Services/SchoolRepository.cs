using Microsoft.EntityFrameworkCore;
using WebApp.Data;
using WebApp.Data.DTO;

namespace WebApp.Services;

public interface ISchoolRepository
{
    void InsertTestData();
    SchoolSummary GetSummary();

    IEnumerable<Student> GetAllStudents();
    Student? GetStudentById(int id);
    Student CreateStudent(Student student);
    bool DeleteStudent(int id);

    IEnumerable<Teacher> GetAllTeachers();
    Teacher? GetTeacherById(int id);
    Teacher CreateTeacher(Teacher teacher);
    bool DeleteTeacher(int id);

    Subject CreateSubject(Subject subject);
}

public class SchoolRepository(MyDbContext dbContext, ILogService logService) : ISchoolRepository
{
    public void InsertTestData()
    {
        dbContext.Database.EnsureCreated();
        if (dbContext.Subjects.Any()) return;

        var teacher = new Teacher { Name = "Anders" };
        var subject = new Subject { Name = "Programmering", Teacher = teacher };
        subject.Students.AddRange(new List<Student> { new Student { Name = "Mikkel" }, new Student { Name = "Sara" } });

        dbContext.Subjects.Add(subject);
        dbContext.SaveChanges();
        logService.LogAction("SYSTEM: Testdata indsat via Seed.");
    }

    // --- SUBJECT (Her fejlede det) ---
    public Subject CreateSubject(Subject subject)
    {
        // Tjek om læreren rent faktisk findes før vi gemmer
        var teacherExists = dbContext.Teachers.Any(t => t.TeacherId == subject.TeacherId);

        if (!teacherExists)
        {
            logService.LogAction($"FEJL: Kunne ikke oprette faget '{subject.Name}', da TeacherId {subject.TeacherId} ikke findes.");
            throw new Exception($"Læreren med ID {subject.TeacherId} findes ikke. Opret læreren først!");
        }

        dbContext.Subjects.Add(subject);
        dbContext.SaveChanges();
        logService.LogAction($"POST: AddSubject - {subject.Name} oprettet til TeacherId {subject.TeacherId}.");
        return subject;
    }

    // --- STUDENT ---
    public IEnumerable<Student> GetAllStudents() { logService.LogAction("GET: Alle elever hentet."); return dbContext.Students.ToList(); }
    public Student? GetStudentById(int id) { logService.LogAction($"GET: Elev ID {id} hentet."); return dbContext.Students.Find(id); }
    public Student CreateStudent(Student student)
    {
        dbContext.Students.Add(student);
        dbContext.SaveChanges();
        logService.LogAction($"POST: AddStudent - {student.Name} oprettet.");
        return student;
    }
    public bool DeleteStudent(int id)
    {
        var s = dbContext.Students.Find(id);
        if (s == null) return false;
        dbContext.Students.Remove(s);
        dbContext.SaveChanges();
        logService.LogAction($"DELETE: Student ID {id} slettet.");
        return true;
    }

    // --- TEACHER ---
    public IEnumerable<Teacher> GetAllTeachers() { logService.LogAction("GET: Alle lærere hentet."); return dbContext.Teachers.ToList(); }
    public Teacher? GetTeacherById(int id) { logService.LogAction($"GET: Lærer ID {id} hentet."); return dbContext.Teachers.Find(id); }
    public Teacher CreateTeacher(Teacher teacher)
    {
        dbContext.Teachers.Add(teacher);
        dbContext.SaveChanges();
        logService.LogAction($"POST: AddTeacher - {teacher.Name} oprettet.");
        return teacher;
    }
    public bool DeleteTeacher(int id)
    {
        var t = dbContext.Teachers.Find(id);
        if (t == null) return false;
        dbContext.Teachers.Remove(t);
        dbContext.SaveChanges();
        logService.LogAction($"DELETE: Teacher ID {id} slettet.");
        return true;
    }

    public SchoolSummary GetSummary()
    {
        logService.LogAction("GET: SchoolSummary hentet.");
        var s = dbContext.Subjects.Include(x => x.Teacher).Include(x => x.Students).FirstOrDefault();
        return s != null ? new SchoolSummary { SubjectName = s.Name, TeacherName = s.Teacher!.Name, StudentCount = s.Students.Count } : new SchoolSummary { SubjectName = "Tom", TeacherName = "Tom", StudentCount = 0 };
    }
}
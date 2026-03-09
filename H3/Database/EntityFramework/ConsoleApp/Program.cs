using ConsoleApp.Data;
using ConsoleApp.Data.DTO;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;

string sqlConn = Environment.GetEnvironmentVariable("DOTNET_CONNECTIONSTRING") ?? "";

/* * NOTER TIL EKSAMEN:
 * CLI (Migrations): Giver fuld kontrol og historik over ændringer.
 * EnsureCreated(): Nemt her og nu, men kan ikke opdatere eksisterende tabeller.
 * Fuld-ORM (EF Core): Arbejder med objekter (C#). God til store komplekse systemer.
 * Mini-ORM (ADO.NET): Arbejder med rå SQL. Hurtigere performance og fuld kontrol.
 * MSSQL: Tung server-database. Kræver installation/Docker.
 * SQLite: Letvægts fil-database. Kræver ingen server (god til client-apps).
 */

while (true)
{
    Console.Clear();
    Console.WriteLine("--- TEC DATABASE MENU ---");
    Console.WriteLine("1: EF Core (MSSQL)");
    Console.WriteLine("2: ADO.NET (Mini-ORM)");
    Console.WriteLine("3: EF Core (SQLite)");
    Console.WriteLine("0: Exit");

    var choice = Console.ReadKey(true).Key;
    if (choice == ConsoleKey.D0) break;

    try
    {
        switch (choice)
        {
            case ConsoleKey.D1:
                RunEfExercise(new MyDbContext()); // MSSQL (Standard context)
                break;
            case ConsoleKey.D2:
                RunMiniOrmExercise(); // ADO.NET
                break;
            case ConsoleKey.D3:
                var options = new DbContextOptionsBuilder<MyDbContext>().UseSqlite("Data Source=TEC.db").Options;
                RunEfExercise(new MyDbContext(options)); // SQLite version
                break;
        }
    }
    catch (Exception) { Console.WriteLine("Fejl: Databasen er ikke klar endnu..."); }

    Console.WriteLine("\nTryk på en tast for at fortsætte...");
    Console.ReadKey(true);
}

// --- EF CORE LOGIK (Øvelse 1 & 3) ---
void RunEfExercise(MyDbContext db)
{
    db.Database.EnsureCreated(); // Opretter DB automatisk hvis den mangler

    if (!db.Subjects.Any())
    {
        db.Subjects.Add(new Subject
        {
            Name = "Programmering",
            Teacher = new Teacher { Name = "Anders (EF)" },
            Students = new List<Student> { new() { Name = "Mikkel" }, new() { Name = "Sara" } }
        });
        db.SaveChanges();
    }

    var s = db.Subjects.Include(x => x.Teacher).Include(x => x.Students).First();
    PrintResult("EF Core", s.Name, s.Teacher.Name, s.Students.Count);
}

// --- ADO.NET LOGIK (Øvelse 2) ---
void RunMiniOrmExercise()
{
    using var conn = new SqlConnection(sqlConn);
    conn.Open();

    // Manuel oprettelse af tabeller
    Execute(conn, @"IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Teachers') BEGIN
        CREATE TABLE Teachers (TeacherId INT PRIMARY KEY IDENTITY, Name NVARCHAR(MAX));
        CREATE TABLE Students (StudentId INT PRIMARY KEY IDENTITY, Name NVARCHAR(MAX));
        CREATE TABLE Subjects (SubjectId INT PRIMARY KEY IDENTITY, Name NVARCHAR(MAX), TeacherId INT FOREIGN KEY REFERENCES Teachers(TeacherId));
        CREATE TABLE StudentSubject (StudentsStudentId INT, SubjectsSubjectId INT, PRIMARY KEY(StudentsStudentId, SubjectsSubjectId));
    END");

    // Indsæt data og få ID retur
    int tId = (int)new SqlCommand("INSERT INTO Teachers (Name) OUTPUT INSERTED.TeacherId VALUES ('Anders (ADO)');", conn).ExecuteScalar();
    int sId = (int)new SqlCommand($"INSERT INTO Subjects (Name, TeacherId) OUTPUT INSERTED.SubjectId VALUES ('Programmering', {tId});", conn).ExecuteScalar();

    // Relationer (Many-to-many)
    Execute(conn, $"INSERT INTO Students (Name) VALUES ('Mikkel'), ('Sara')");
    Execute(conn, $"INSERT INTO StudentSubject SELECT StudentId, {sId} FROM Students WHERE Name IN ('Mikkel', 'Sara')");

    // Læs data med Join
    using var reader = new SqlCommand(@"SELECT sub.Name, t.Name, COUNT(ss.StudentsStudentId) 
        FROM Subjects sub JOIN Teachers t ON sub.TeacherId = t.TeacherId 
        JOIN StudentSubject ss ON sub.SubjectId = ss.SubjectsSubjectId
        GROUP BY sub.Name, t.Name", conn).ExecuteReader();

    if (reader.Read())
        PrintResult("ADO.NET", reader[0].ToString(), reader[1].ToString(), (int)reader[2]);
}

void Execute(SqlConnection c, string sql) => new SqlCommand(sql, c).ExecuteNonQuery();

void PrintResult(string type, string sub, string tea, int count) =>
    Console.WriteLine($"[{type}] {sub} undervises af {tea} og har {count} elever.");
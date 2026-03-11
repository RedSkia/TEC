using Microsoft.EntityFrameworkCore;
using ConsoleApp.Data;
using ConsoleApp.Services;

// 1. Connection strings
string baseConn = "Server=mssql;User Id=sa;Password=DbPassw0rd;Encrypt=False;TrustServerCertificate=True;";
string tecConn = baseConn + "Database=TEC;";
string hokConn = baseConn + "Database=HØK;";

// 2. Setup TEC (Onion: Vi injecter Infrastructure ind i Presentation)
var tecOptions = new DbContextOptionsBuilder<MyDbContext>().UseSqlServer(tecConn).Options;
ISchoolRepository tecRepo = new SchoolRepository(new MyDbContext(tecOptions));

// 3. Setup HØK
var hokOptions = new DbContextOptionsBuilder<MyDbContext>().UseSqlServer(hokConn).Options;
ISchoolRepository hokRepo = new SchoolRepository(new MyDbContext(hokOptions));

// 4. Afvikling (Opgave 1 & 2)
SeedAndPrint("TEC", tecRepo);
SeedAndPrint("HØK", hokRepo);

void SeedAndPrint(string dbName, ISchoolRepository repo)
{
    repo.AddData("Programmering", "Anders", new List<string> { "Mikkel", "Sara" });
    var res = repo.GetSummary();
    Console.WriteLine($"{dbName}: {res.subject} undervises af {res.teacher} og har {res.count} elever.");
}

// Slet TEC
//dotnet ef database drop --connection "Server=localhost;Database=TEC;User Id=sa;Password=DbPassw0rd;Encrypt=False;TrustServerCertificate=True;" --force
// Slet HØK
//dotnet ef database drop --connection "Server=localhost;Database=HØK;User Id=sa;Password=DbPassw0rd;Encrypt=False;TrustServerCertificate=True;" --force
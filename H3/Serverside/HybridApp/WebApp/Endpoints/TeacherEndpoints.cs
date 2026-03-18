using WebApp.Data.DTO;
using WebApp.Services;

namespace WebApp.Endpoints;

public static class TeacherEndpoints
{
    // Vi bruger this WebApplication for at opfylde kravet om en Extension Method
    public static void MapTeacherEndpoints(this WebApplication app)
    {
        // Opretter en basisrute, så vi ikke skal skrive hele URL'en i hvert kald
        var group = app.MapGroup("/api/teacher");

        group.MapGet("/", (ISchoolRepository repo) =>
        {
            var teachers = repo.GetAllTeachers();
            return Results.Ok(teachers);
        });

        group.MapGet("/{id:int}", (int id, ISchoolRepository repo) =>
        {
            var teacher = repo.GetTeacherById(id);
            // Returner læreren hvis fundet, ellers giv en standard 404 fejl
            return teacher is not null ? Results.Ok(teacher) : Results.NotFound();
        });

        group.MapPost("/", (Teacher newTeacher, ISchoolRepository repo) =>
        {
            if (string.IsNullOrWhiteSpace(newTeacher.Name))
                return Results.BadRequest("Navn er påkrævet.");

            var created = repo.CreateTeacher(newTeacher);

            // KRAV 3: Log til tekstfil (AddTeacher)
            var logMessage = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] AddTeacher kaldt. Lærer oprettet: {created.Name}\n";
            System.IO.File.AppendAllText("log.txt", logMessage);

            return Results.Created($"/api/teacher/{created.TeacherId}", created);
        });

        group.MapDelete("/{id:int}", (int id, ISchoolRepository repo) =>
        {
            var success = repo.DeleteTeacher(id);
            return success ? Results.NoContent() : Results.NotFound();
        });
    }
}
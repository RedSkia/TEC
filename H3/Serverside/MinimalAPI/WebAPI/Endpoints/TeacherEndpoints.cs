using WebAPI.Data.DTO;
using WebAPI.Services;

namespace WebAPI.Endpoints;

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
            // Simpel validering for at sikre, at vi ikke får tomme navne i databasen
            if (string.IsNullOrWhiteSpace(newTeacher.Name))
                return Results.BadRequest("Navn er påkrævet.");

            var created = repo.CreateTeacher(newTeacher);

            // Giver en pæn HTTP 201 tilbage sammen med en henvisning til det nye objekt
            return Results.Created($"/api/teacher/{created.TeacherId}", created);
        });

        group.MapDelete("/{id:int}", (int id, ISchoolRepository repo) =>
        {
            var success = repo.DeleteTeacher(id);
            return success ? Results.NoContent() : Results.NotFound();
        });
    }
}
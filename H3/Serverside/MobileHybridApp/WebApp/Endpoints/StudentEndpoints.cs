using WebApp.Data.DTO;
using WebApp.Services;

namespace WebApp.Endpoints;

public static class StudentEndpoints
{
    public static void MapStudentEndpoints(this WebApplication app)
    {
        // Vi beholder /api/school/students ruten her for at matche den tidligere controller-version
        var group = app.MapGroup("/api/school/students");

        group.MapGet("/", (ISchoolRepository repo) =>
        {
            var students = repo.GetAllStudents();
            return Results.Ok(students);
        });

        group.MapGet("/{id:int}", (int id, ISchoolRepository repo) =>
        {
            var student = repo.GetStudentById(id);
            return student is not null ? Results.Ok(student) : Results.NotFound();
        });

        group.MapPost("/", (Student newStudent, ISchoolRepository repo) =>
        {
            if (string.IsNullOrWhiteSpace(newStudent.Name))
                return Results.BadRequest("Navn er påkrævet.");

            var created = repo.CreateStudent(newStudent);
            return Results.Created($"/api/school/students/{created.StudentId}", created);
        });

        group.MapDelete("/{id:int}", (int id, ISchoolRepository repo) =>
        {
            var success = repo.DeleteStudent(id);
            return success ? Results.NoContent() : Results.NotFound();
        });

        // --- Ekstra funktioner tilknyttet skolen ---

        // Genbrug af vores seed-logik direkte på roden af /api/school
        app.MapPost("/api/school/seed", (ISchoolRepository repo) =>
        {
            try
            {
                repo.InsertTestData();
                return Results.Ok(new { message = "Data indsat via Minimal API." });
            }
            catch (Exception ex)
            {
                // Returner en 500 statuskode, hvis databasen fx ikke er klar
                return Results.Problem(ex.Message);
            }
        });

        app.MapGet("/api/school/summary", (ISchoolRepository repo) =>
        {
            try
            {
                var summary = repo.GetSummary();
                return Results.Ok(summary);
            }
            catch
            {
                // Hvis First() fejler i repository, betyder det at databasen er tom
                return Results.NotFound("Ingen data fundet. Kør seed først.");
            }
        });
    }
}
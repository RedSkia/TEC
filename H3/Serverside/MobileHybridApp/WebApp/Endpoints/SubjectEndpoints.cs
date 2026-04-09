using WebApp.Data.DTO;
using WebApp.Services;

namespace WebApp.Endpoints;

public static class SubjectEndpoints
{
    public static void MapSubjectEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/subjects");

        group.MapPost("/", (Subject newSubject, ISchoolRepository repo) =>
        {
            try
            {
                if (string.IsNullOrWhiteSpace(newSubject.Name))
                    return Results.BadRequest("Fagets navn er påkrævet.");

                var created = repo.CreateSubject(newSubject);
                return Results.Created($"/api/subjects/{created.SubjectId}", created);
            }
            catch (Exception ex)
            {
                // Returnerer fejlen om at læreren mangler til Swagger
                return Results.BadRequest(ex.Message);
            }
        });
    }
}
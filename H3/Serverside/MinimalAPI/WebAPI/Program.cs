using Microsoft.EntityFrameworkCore;
using WebAPI.Data;
using WebAPI.Endpoints;
using WebAPI.Services;

var builder = WebApplication.CreateBuilder(args);

// Gør klar til automatisk dokumentation via Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Sætter database-forbindelsen op via Connection String fra vores Docker miljø
builder.Services.AddDbContext<MyDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Fortæller programmet, at når et endpoint beder om ISchoolRepository, 
// skal det modtage en ny instans af SchoolRepository (Dependency Injection)
builder.Services.AddScoped<ISchoolRepository, SchoolRepository>();

var app = builder.Build();

// Opsætning af Swagger interfacet, så det er klar med det samme
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "v1");
    options.RoutePrefix = string.Empty; // Sætter Swagger som forside
    options.EnableTryItOutByDefault();  // Knapperne er låst op fra start
});

// Registrerer vores to endpoint klasser i applikationen
app.MapTeacherEndpoints();
app.MapStudentEndpoints();
// app.MapSubjectEndpoints(); // Klar til at blive slået til, hvis det kræves

app.Run();
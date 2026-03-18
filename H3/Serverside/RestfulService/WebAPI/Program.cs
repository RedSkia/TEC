using Microsoft.EntityFrameworkCore;
using WebAPI.Data;
using WebAPI.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<MyDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<ISchoolRepository, SchoolRepository>();

var app = builder.Build();

// FLYTTET UD: Swagger aktiveres nu altid, så vi kan se den i Docker
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "v1");
    options.RoutePrefix = string.Empty; // Swagger åbner nu på http://localhost:8080/
    options.EnableTryItOutByDefault();
});

// FJERN HTTPS: Docker containere kører internt på HTTP (port 8080)
// app.UseHttpsRedirection(); 

app.UseAuthorization();
app.MapControllers();

app.Run();
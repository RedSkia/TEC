using Microsoft.EntityFrameworkCore;
using WebApp.Data;
using WebApp.Endpoints;
using WebApp.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<MyDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// VIGTIGT: LogService skal være Singleton for at bevare event-tilstand
builder.Services.AddSingleton<ILogService, LogService>();
builder.Services.AddScoped<ISchoolRepository, SchoolRepository>();

var app = builder.Build();

// Auto-seed ved opstart
using (var scope = app.Services.CreateScope())
{
    var repo = scope.ServiceProvider.GetRequiredService<ISchoolRepository>();
    repo.InsertTestData();
}

app.UseStaticFiles();
app.UseRouting();
app.UseSwagger();
app.UseSwaggerUI(options => {
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "v1");
    options.EnableTryItOutByDefault();
});

// Endpoint til live-opdatering af loggen
app.MapGet("/api/log", (ILogService logService) => Results.Content(logService.ReadLog()));
app.MapDelete("/api/log", (ILogService logService) =>
{
    logService.DeleteLog();
    return Results.NoContent();
});

app.MapRazorPages();
app.MapTeacherEndpoints();
app.MapStudentEndpoints();
app.MapSubjectEndpoints();

app.Run();
using Microsoft.AspNetCore.Mvc;
using WebAPI.Data.DTO;
using WebAPI.Services;

namespace WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SchoolController : ControllerBase
{
    private readonly ISchoolRepository _repo;

    public SchoolController(ISchoolRepository repo)
    {
        _repo = repo;
    }

    [HttpPost("seed")]
    public IActionResult SeedData()
    {
        try
        {
            _repo.InsertTestData();
            return Ok(new { message = "Data indsat i databasen." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, "Fejl: " + ex.Message);
        }
    }

    [HttpGet("summary")]
    public ActionResult<SchoolSummary> GetSummary()
    {
        try
        {
            var result = _repo.GetSummary();
            return Ok(result);
        }
        catch (Exception)
        {
            return NotFound("Ingen data fundet. Har du husket at køre seed-endpointet?");
        }
    }

    // --- NYE CRUD ENDPOINTS ---

    // GET: api/school/students
    [HttpGet("students")]
    public ActionResult<IEnumerable<Student>> GetAllStudents()
    {
        var students = _repo.GetAllStudents();
        return Ok(students);
    }

    // GET: api/school/students/5
    [HttpGet("students/{id}")]
    public ActionResult<Student> GetStudent(int id)
    {
        var student = _repo.GetStudentById(id);
        if (student == null) return NotFound($"Studerende med ID {id} blev ikke fundet.");

        return Ok(student);
    }

    // POST: api/school/students
    [HttpPost("students")]
    public ActionResult<Student> CreateStudent([FromBody] Student newStudent)
    {
        if (string.IsNullOrWhiteSpace(newStudent.Name))
            return BadRequest("Navn er påkrævet.");

        var createdStudent = _repo.CreateStudent(newStudent);

        // Returnerer 201 Created og sender et link til det nye objekt
        return CreatedAtAction(nameof(GetStudent), new { id = createdStudent.StudentId }, createdStudent);
    }

    // DELETE: api/school/students/5
    [HttpDelete("students/{id}")]
    public IActionResult DeleteStudent(int id)
    {
        var success = _repo.DeleteStudent(id);
        if (!success) return NotFound($"Studerende med ID {id} blev ikke fundet.");

        return NoContent(); // 204 No Content er standard for en succesfuld sletning
    }
}
namespace WebAPI.Data.DTO;

public class SchoolSummary
{
    public required string SubjectName { get; set; }
    public required string TeacherName { get; set; }
    public int StudentCount { get; set; }
}

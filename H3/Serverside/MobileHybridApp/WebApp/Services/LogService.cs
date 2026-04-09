namespace WebApp.Services;

public interface ILogService
{
    event Action<string>? OnLogChanged;
    void LogAction(string message);
    string ReadLog();
    void DeleteLog();
}

public class LogService : ILogService
{
    private readonly string _logPath = "log.txt";
    public event Action<string>? OnLogChanged;

    public void LogAction(string message)
    {
        var logLine = $"[{DateTime.Now:dd-MM-yyyy HH:mm:ss}] {message}\n";
        File.AppendAllText(_logPath, logLine);
        OnLogChanged?.Invoke(logLine);
    }

    public string ReadLog()
    {
        return File.Exists(_logPath) ? File.ReadAllText(_logPath) : "Loggen er tom...";
    }

    public void DeleteLog()
    {
        if (File.Exists(_logPath))
        {
            File.Delete(_logPath);
        }
        OnLogChanged?.Invoke("Log slettet.");
    }
}
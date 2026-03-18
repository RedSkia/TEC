using Microsoft.AspNetCore.Mvc.RazorPages;
using WebApp.Services;

namespace WebApp.Pages; // Sørg for at dette matcher dit faktiske namespace

public class IndexModel(ILogService logService) : PageModel
{
    public string LogContent { get; set; } = string.Empty;

    public void OnGet()
    {
        // Kravet: Hent loggen hver gang siden opdateres
        LogContent = logService.ReadLog();
    }
}
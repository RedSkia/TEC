using Microsoft.Extensions.Logging;

namespace MauiBlazorHybridApp
{
    public static class MauiProgram
    {
        public static MauiApp CreateMauiApp()
        {
            var builder = MauiApp.CreateBuilder();
            builder
                .UseMauiApp<App>()
                .ConfigureFonts(fonts =>
                {
                    fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                });

            builder.Services.AddMauiBlazorWebView();

            // DEN MAGISKE KODE: Tjekker automatisk platformen
#if ANDROID
            string apiUrl = "http://10.0.2.2:8080";
#else
            string apiUrl = "http://localhost:8080";
#endif
            builder.Services.AddScoped(sp => new HttpClient { BaseAddress = new Uri(apiUrl) });

#if DEBUG
            builder.Services.AddBlazorWebViewDeveloperTools();
            builder.Logging.AddDebug();
#endif

            return builder.Build();
        }
    }
}
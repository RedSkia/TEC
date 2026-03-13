// Services/MarketWorker.cs
namespace BankApp.Services;

public class MarketWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    public MarketWorker(IServiceProvider serviceProvider) => _serviceProvider = serviceProvider;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            using (var scope = _serviceProvider.CreateScope())
            {
                var stockService = scope.ServiceProvider.GetRequiredService<IStockService>();
                await stockService.UpdateMarketPricesAsync();
            }
            await Task.Delay(1000, stoppingToken);
        }
    }
}
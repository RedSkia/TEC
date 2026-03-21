using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SharedCore.Data;
using SharedCore.Entities.Banking;
using System;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace BlazorApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CheckoutController(IDbContextFactory<BankAppDbContext> dbFactory) : ControllerBase
{
    private readonly HttpClient _httpClient = new();

    [HttpPost("create")]
    public async Task<IActionResult> CreateIntent([FromBody] CheckoutRequest request)
    {
        using var db = await dbFactory.CreateDbContextAsync();

        var intent = new PaymentIntent
        {
            Amount = request.Amount,
            MerchantName = request.MerchantName,
            WebhookUrl = request.WebhookUrl,
            ReceiverBankAccountId = request.MerchantBankAccountId,
            Status = PaymentIntentStatus.Pending
        };

        db.PaymentIntents.Add(intent);
        await db.SaveChangesAsync();

        // Dynamisk URL-generering i stedet for hardcoded localhost!
        var baseUrl = $"{Request.Scheme}://{Request.Host}";
        var redirectUrl = $"{baseUrl}/api/checkout/{intent.Id}";

        return Ok(new { redirectUrl });
    }

    [HttpGet("intent/{id}")]
    public async Task<IActionResult> GetIntent(Guid id)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var intent = await db.PaymentIntents
            .Include(p => p.ReceiverBankAccount)
            .AsNoTracking()
            .FirstOrDefaultAsync(i => i.Id == id);

        if (intent == null) return NotFound();
        return Ok(intent);
    }

    [HttpPost("finalize/{intentId}")]
    public async Task<IActionResult> Finalize(Guid intentId, [FromQuery] int senderAccountId)
    {
        using var db = await dbFactory.CreateDbContextAsync();
        var intent = await db.PaymentIntents.FirstOrDefaultAsync(i => i.Id == intentId);

        if (intent == null || intent.Status != PaymentIntentStatus.Pending) return BadRequest();

        intent.SenderBankAccountId = senderAccountId;
        intent.Status = PaymentIntentStatus.Completed;
        await db.SaveChangesAsync();

        // Kør webhook kald i baggrunden uden at blokere
        _ = Task.Run(async () => {
            try
            {
                await _httpClient.PostAsJsonAsync(intent.WebhookUrl, new { intentId = intent.Id, status = "SUCCESS" });
            }
            catch { /* Log webhook fejl stille */ }
        });

        return Ok();
    }
}

public record CheckoutRequest(decimal Amount, string MerchantName, string WebhookUrl, int MerchantBankAccountId);
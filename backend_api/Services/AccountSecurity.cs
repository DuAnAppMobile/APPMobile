using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using EnglishRpg.Api.Data;
using EnglishRpg.Api.Dtos;
using EnglishRpg.Api.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace EnglishRpg.Api.Services;

public static class AccountSecurity
{
    public static string HashToken(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    public static int PlayerId(this ClaimsPrincipal user) => int.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

public sealed class SessionAuthentication(IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger, UrlEncoder encoder, AppDbContext db)
    : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var header = Request.Headers.Authorization.ToString();
        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)) return AuthenticateResult.NoResult();
        var token = header[7..];
        if (token.Length != 64) return AuthenticateResult.Fail("Invalid session");
        var hash = AccountSecurity.HashToken(token);
        var session = await db.LoginSessions.Include(s => s.Account)
            .FirstOrDefaultAsync(s => s.TokenHash == hash, Context.RequestAborted);
        if (session is null || session.ExpiresAt <= DateTime.UtcNow) return AuthenticateResult.Fail("Expired session");
        var claims = new[] {new Claim(ClaimTypes.NameIdentifier, session.Account.PlayerId.ToString()),
            new Claim("session", hash), new Claim(ClaimTypes.Name, session.Account.Username),
            new Claim(ClaimTypes.Role, session.Account.Role)};
        return AuthenticateResult.Success(new AuthenticationTicket(new ClaimsPrincipal(
            new ClaimsIdentity(claims, Scheme.Name)), Scheme.Name));
    }
}

// Every identifier-bearing legacy route is checked, not just the account endpoint.
public sealed class PlayerOwnershipFilter(AppDbContext db) : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        if (context.HttpContext.User.Identity?.IsAuthenticated != true) { await next(); return; }
        var playerId = context.HttpContext.User.PlayerId();
        var args = context.ActionArguments;
        var invalid = args.TryGetValue("playerId", out var requested) && requested is int id && id != playerId;
        if (context.Controller is Controllers.PlayersController && args.TryGetValue("id", out var value) && value is int routeId)
            invalid |= routeId != playerId;
        if (args.TryGetValue("request", out var request) && request is StartStageAttemptRequest start)
            invalid |= start.PlayerId != playerId;
        if (args.TryGetValue("attemptId", out var attempt) && attempt is int attemptId)
            invalid |= !await db.StageAttempts.AnyAsync(a => a.Id == attemptId && a.PlayerId == playerId,
                context.HttpContext.RequestAborted);
        if (invalid) { context.Result = new ForbidResult(); return; }
        await next();
    }
}

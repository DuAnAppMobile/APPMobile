using System.Security.Cryptography;
using System.Text.RegularExpressions;
using EnglishRpg.Api.Data;
using EnglishRpg.Api.Models;
using EnglishRpg.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace EnglishRpg.Api.Controllers;

[ApiController, Route("api/auth")]
public sealed class AuthController(AppDbContext db, IPlayerService players) : ControllerBase
{
    public sealed record Credentials(string? Username, string? Password);
    private static readonly PasswordHasher<Account> Hasher = new(Microsoft.Extensions.Options.Options.Create(
        new PasswordHasherOptions { IterationCount = 600000 }));
    private static readonly Account Dummy = new() { Username = "dummy", PasswordHash = "" };
    private static readonly string DummyHash = Hasher.HashPassword(Dummy, "not-an-account-password");

    [AllowAnonymous, EnableRateLimiting("auth"), HttpPost("register")]
    public async Task<IActionResult> Register(Credentials request, CancellationToken ct)
    {
        var name = request.Username?.Trim().ToLowerInvariant() ?? "";
        if (!Regex.IsMatch(name, "^[a-z0-9_]{3,32}$") || request.Password is null ||
            request.Password.Length is < 10 or > 128 || !request.Password.Any(char.IsLetter) || !request.Password.Any(char.IsDigit))
            return BadRequest(new {message = "Tài khoản: 3–32 chữ không dấu, số hoặc _. Mật khẩu: 10–128 ký tự, có chữ và số."});
        if (await db.Accounts.AnyAsync(a => a.Username == name, ct))
            return Conflict(new {message = "Tên tài khoản đã được sử dụng."});
        var account = new Account {Username = name, PasswordHash = "",
            Player = new Player { Name = name, CreatedAt = DateTime.UtcNow }};
        account.PasswordHash = Hasher.HashPassword(account, request.Password);
        db.Accounts.Add(account);
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateException) { return Conflict(new {message = "Không thể tạo tài khoản với tên này. Hãy chọn tên khác."}); }
        return await CreateSession(account, ct);
    }

    [AllowAnonymous, EnableRateLimiting("auth"), HttpPost("login")]
    public async Task<IActionResult> Login(Credentials request, CancellationToken ct)
    {
        var name = request.Username?.Trim().ToLowerInvariant() ?? "";
        if (name.Length > 32 || request.Password is null || request.Password.Length > 128)
            return Unauthorized(new {message = "Sai tài khoản hoặc mật khẩu."});
        var account = await db.Accounts.SingleOrDefaultAsync(a => a.Username == name, ct);
        var verification = Hasher.VerifyHashedPassword(account ?? Dummy, account?.PasswordHash ?? DummyHash, request.Password);
        if (account is null || account.LockedUntil > DateTime.UtcNow || verification == PasswordVerificationResult.Failed)
        {
            if (account is not null && !(account.LockedUntil > DateTime.UtcNow)) {
                account.FailedLogins++;
                if (account.FailedLogins >= 5) { account.LockedUntil = DateTime.UtcNow.AddMinutes(5); account.FailedLogins = 0; }
                await db.SaveChangesAsync(ct);
            }
            return Unauthorized(new {message = "Sai tài khoản/mật khẩu hoặc tài khoản đang tạm khóa. Thử lại sau nếu đã nhập sai nhiều lần."});
        }
        account.FailedLogins = 0; account.LockedUntil = null;
        if (verification == PasswordVerificationResult.SuccessRehashNeeded)
            account.PasswordHash = Hasher.HashPassword(account, request.Password);
        return await CreateSession(account, ct);
    }

    private async Task<IActionResult> CreateSession(Account account, CancellationToken ct)
    {
        await db.LoginSessions.Where(s => s.ExpiresAt <= DateTime.UtcNow).ExecuteDeleteAsync(ct);
        var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        var expiresAt = DateTime.UtcNow.AddDays(7);
        db.LoginSessions.Add(new LoginSession {TokenHash = AccountSecurity.HashToken(token),
            AccountId = account.Id, ExpiresAt = expiresAt});
        await db.SaveChangesAsync(ct);
        return Ok(new { token, expiresAt, role = account.Role, player = await players.GetPlayerByIdAsync(account.PlayerId, ct) });
    }

    public sealed record PasswordChange(string? CurrentPassword, string? NewPassword);
    public sealed record PasswordReset(string? Username, string? Code, string? NewPassword);
    private static bool ValidPassword(string? value) => value is { Length: >= 10 and <= 128 } && value.Any(char.IsLetter) && value.Any(char.IsDigit);
    // Domain-separated recovery hashes cannot authenticate as bearer sessions.
    private static string RecoveryHash(string code) => "R" + AccountSecurity.HashToken("recovery:" + code)[..63];

    [HttpPost("change-password"), EnableRateLimiting("auth")]
    public async Task<IActionResult> ChangePassword(PasswordChange request, CancellationToken ct)
    {
        if (!ValidPassword(request.NewPassword)) return BadRequest(new { message = "Mật khẩu mới cần 10–128 ký tự, có chữ và số." });
        var account = await db.Accounts.SingleAsync(a => a.PlayerId == User.PlayerId(), ct);
        if (request.CurrentPassword is null || request.CurrentPassword.Length > 128 || Hasher.VerifyHashedPassword(account, account.PasswordHash, request.CurrentPassword) == PasswordVerificationResult.Failed)
            return BadRequest(new { message = "Mật khẩu hiện tại chưa đúng." });
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        account.PasswordHash = Hasher.HashPassword(account, request.NewPassword!);
        await db.LoginSessions.Where(s => s.AccountId == account.Id).ExecuteDeleteAsync(ct);
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return NoContent();
    }

    [HttpPost("recovery-code"), EnableRateLimiting("auth")]
    public async Task<IActionResult> RecoveryCode(PasswordChange request, CancellationToken ct)
    {
        var account = await db.Accounts.SingleAsync(a => a.PlayerId == User.PlayerId(), ct);
        if (request.CurrentPassword is null || request.CurrentPassword.Length > 128 || Hasher.VerifyHashedPassword(account, account.PasswordHash, request.CurrentPassword) == PasswordVerificationResult.Failed)
            return BadRequest(new { message = "Mật khẩu hiện tại chưa đúng." });
        var code = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await db.LoginSessions.Where(s => s.AccountId == account.Id && s.TokenHash.StartsWith("R")).ExecuteDeleteAsync(ct);
        var expiresAt = DateTime.UtcNow.AddDays(90);
        db.LoginSessions.Add(new LoginSession { AccountId = account.Id, TokenHash = RecoveryHash(code), ExpiresAt = expiresAt });
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return Ok(new { code, expiresAt });
    }

    [AllowAnonymous, HttpPost("reset-password"), EnableRateLimiting("auth")]
    public async Task<IActionResult> ResetPassword(PasswordReset request, CancellationToken ct)
    {
        if (!ValidPassword(request.NewPassword)) return BadRequest(new { message = "Mật khẩu mới cần 10–128 ký tự, có chữ và số." });
        if (request.Code is not { Length: 64 } || request.Username is not { Length: <= 32 })
            return BadRequest(new { message = "Tài khoản hoặc mã khôi phục không hợp lệ." });
        var hash = RecoveryHash(request.Code.Trim().ToUpperInvariant());
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        var recovery = await db.LoginSessions.Include(s => s.Account).SingleOrDefaultAsync(s => s.TokenHash == hash, ct);
        if (recovery is null || recovery.ExpiresAt <= DateTime.UtcNow || recovery.Account.Username != request.Username.Trim().ToLowerInvariant())
            return BadRequest(new { message = "Tài khoản hoặc mã khôi phục không hợp lệ, đã dùng hoặc hết hạn." });
        var account = recovery.Account;
        account.PasswordHash = Hasher.HashPassword(account, request.NewPassword!);
        account.FailedLogins = 0; account.LockedUntil = null;
        await db.LoginSessions.Where(s => s.AccountId == account.Id).ExecuteDeleteAsync(ct);
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return NoContent();
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout(CancellationToken ct)
    {
        var hash = User.FindFirst("session")!.Value;
        await db.LoginSessions.Where(s => s.TokenHash == hash).ExecuteDeleteAsync(ct);
        return NoContent();
    }
}

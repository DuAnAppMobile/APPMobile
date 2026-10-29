namespace EnglishRpg.Api.Models;

public class Account
{
    public int Id { get; set; }
    public required string Username { get; set; }
    public required string PasswordHash { get; set; }
    public string Role { get; set; } = "User";
    public int PlayerId { get; set; }
    public Player Player { get; set; } = null!;
    public int FailedLogins { get; set; }
    public DateTime? LockedUntil { get; set; }
}
public class LoginSession
{
    public required string TokenHash { get; set; }
    public int AccountId { get; set; }
    public Account Account { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
}
public class PracticeRecord
{
    public int PlayerId { get; set; }
    public Player Player { get; set; } = null!;
    public required string QuestionId { get; set; }
    public bool IsCorrect { get; set; }
}

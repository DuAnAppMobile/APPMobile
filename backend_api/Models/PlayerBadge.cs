namespace EnglishRpg.Api.Models;

public class PlayerBadge
{
    public int PlayerId { get; set; }
    public int BadgeId { get; set; }

    public Player Player { get; set; } = null!;
    public Badge Badge { get; set; } = null!;
}

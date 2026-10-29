namespace EnglishRpg.Api.Models;

public class Badge
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public required string Description { get; set; }
    public required string IconUrl { get; set; }

    public ICollection<PlayerBadge> Players { get; set; } = new List<PlayerBadge>();
}

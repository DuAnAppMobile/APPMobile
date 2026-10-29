namespace EnglishRpg.Api.Models;

public class Player
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public string AvatarId { get; set; } = "default_avatar";
    public int? TargetUniversityId { get; set; }
    public int TotalExp { get; set; }
    public DateTime CreatedAt { get; set; }

    public University? TargetUniversity { get; set; }
    public ICollection<PlayerStageProgress> StageProgress { get; set; } = new List<PlayerStageProgress>();
    public ICollection<StageAttempt> StageAttempts { get; set; } = new List<StageAttempt>();
    public ICollection<PlayerBadge> Badges { get; set; } = new List<PlayerBadge>();
}

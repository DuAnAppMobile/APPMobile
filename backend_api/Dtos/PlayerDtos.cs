namespace EnglishRpg.Api.Dtos;

public class PlayerLoginRequest
{
    public string Name { get; set; } = string.Empty;
}

public class SetPlayerTargetRequest
{
    public int UniversityId { get; set; }
}

public class SetPlayerAvatarRequest
{
    public string AvatarId { get; set; } = string.Empty;
}

public class UniversitySummaryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ShortName { get; set; } = string.Empty;
    public int ExpRequired { get; set; }
}

public class PlayerResponseDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string AvatarId { get; set; } = "default_avatar";
    public int TotalExp { get; set; }
    public int? TargetUniversityId { get; set; }
    public UniversitySummaryDto? TargetUniversity { get; set; }
    public bool IsTargetUnlocked { get; set; }
}

public class PlayerProfileDto
{
    public string Name { get; set; } = string.Empty;
    public int TotalExp { get; set; }
    public string AvatarId { get; set; } = "default_avatar";
    public List<BadgeDto> Badges { get; set; } = [];
}

public class PlayerHistoryDto
{
    public int CompensationExp { get; set; }
    public bool HasAdjustedQuestions { get; set; }
    public int AttemptId { get; set; }
    public string StageName { get; set; } = string.Empty;
    public int CorrectCount { get; set; }
    public int TotalQuestions { get; set; }
    public int ExpEarned { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime PlayedAt { get; set; }
}

public class BadgeDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string IconUrl { get; set; } = string.Empty;
}

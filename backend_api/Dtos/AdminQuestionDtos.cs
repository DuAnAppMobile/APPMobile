using System.ComponentModel.DataAnnotations;

namespace EnglishRpg.Api.Dtos;

public sealed class SaveQuestionRequest
{
    [Range(1, int.MaxValue)]
    public int StageId { get; set; }

    [Required]
    public string Content { get; set; } = string.Empty;

    [Required, StringLength(1000)]
    public string OptionA { get; set; } = string.Empty;

    [Required, StringLength(1000)]
    public string OptionB { get; set; } = string.Empty;

    [Required, StringLength(1000)]
    public string OptionC { get; set; } = string.Empty;

    [Required, StringLength(1000)]
    public string OptionD { get; set; } = string.Empty;

    [Required, RegularExpression("^[A-Da-d]$")]
    public string CorrectOption { get; set; } = string.Empty;

    public string? Hint1 { get; set; }
    public string? Hint2 { get; set; }
    public string? Explanation { get; set; }
}

public sealed record AdminQuestionDto(
    int Id,
    int StageId,
    string Content,
    string OptionA,
    string OptionB,
    string OptionC,
    string OptionD,
    string CorrectOption,
    string? Hint1,
    string? Hint2,
    string? Explanation);

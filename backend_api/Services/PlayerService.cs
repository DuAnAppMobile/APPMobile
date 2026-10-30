using EnglishRpg.Api.Data;
using EnglishRpg.Api.Dtos;
using EnglishRpg.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace EnglishRpg.Api.Services;

public class PlayerService(AppDbContext dbContext) : IPlayerService
{
    public async Task<PlayerResponseDto> GetPlayerByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var player = await dbContext.Players
            .Include(currentPlayer => currentPlayer.TargetUniversity)
            .FirstOrDefaultAsync(currentPlayer => currentPlayer.Id == id, cancellationToken);

        if (player is null)
        {
            throw new KeyNotFoundException($"Player with id {id} was not found.");
        }

        return MapPlayer(player);
    }

    public async Task<PlayerProfileDto> GetPlayerProfileAsync(int id, CancellationToken cancellationToken = default)
    {
        var player = await dbContext.Players
            .AsNoTracking()
            .Where(currentPlayer => currentPlayer.Id == id)
            .Select(currentPlayer => new PlayerProfileDto
            {
                Name = currentPlayer.Name,
                TotalExp = currentPlayer.TotalExp,
                AvatarId = currentPlayer.AvatarId,
                Badges = currentPlayer.Badges
                    .Select(playerBadge => new BadgeDto
                    {
                        Id = playerBadge.Badge.Id,
                        Name = playerBadge.Badge.Name,
                        Description = playerBadge.Badge.Description,
                        IconUrl = playerBadge.Badge.IconUrl
                    })
                    .ToList()
            })
            .FirstOrDefaultAsync(cancellationToken);

        return player ?? throw new KeyNotFoundException($"Player with id {id} was not found.");
    }

    public async Task<List<PlayerHistoryDto>> GetPlayerHistoryAsync(int id, CancellationToken cancellationToken = default)
    {
        var attempts = await dbContext.StageAttempts
            .AsNoTracking()
            .Where(attempt => attempt.PlayerId == id &&
                              attempt.FinishedAt != null &&
                              (attempt.Status == StageAttemptStatus.Passed ||
                               attempt.Status == StageAttemptStatus.Failed))
            .OrderByDescending(attempt => attempt.FinishedAt)
            .Select(attempt => new
            {
                AttemptId = attempt.Id,
                attempt.CompensationExp,
                HasAdjustedQuestions = attempt.AttemptQuestions.Any(q => q.Question.IsVoided || q.Question.CorrectionOption != null),
                StageName = attempt.Stage.Name,
                attempt.CorrectCount,
                TotalQuestions = attempt.AttemptQuestions.Count,
                attempt.ExpEarned,
                attempt.Status,
                PlayedAt = attempt.FinishedAt!.Value
            })
            .ToListAsync(cancellationToken);

        return attempts
            .Select(attempt => new PlayerHistoryDto
            {
                AttemptId = attempt.AttemptId,
                CompensationExp = attempt.CompensationExp,
                HasAdjustedQuestions = attempt.HasAdjustedQuestions,
                StageName = attempt.StageName,
                CorrectCount = attempt.CorrectCount,
                TotalQuestions = attempt.TotalQuestions,
                ExpEarned = attempt.ExpEarned,
                Status = attempt.Status.ToString(),
                PlayedAt = attempt.PlayedAt
            })
            .ToList();
    }

    public async Task<PlayerResponseDto> SetTargetUniversityAsync(int id, int universityId, CancellationToken cancellationToken = default)
    {
        if (universityId <= 0)
        {
            throw new ArgumentException("University id must be greater than zero.", nameof(universityId));
        }

        var player = await dbContext.Players
            .Include(currentPlayer => currentPlayer.TargetUniversity)
            .FirstOrDefaultAsync(currentPlayer => currentPlayer.Id == id, cancellationToken);

        if (player is null)
        {
            throw new KeyNotFoundException($"Player with id {id} was not found.");
        }

        var university = await dbContext.Universities
            .FirstOrDefaultAsync(item => item.Id == universityId, cancellationToken);

        if (university is null)
        {
            throw new KeyNotFoundException($"University with id {universityId} was not found.");
        }

        if (player.TargetUniversityId is not null && player.TargetUniversityId != universityId)
        {
            throw new InvalidOperationException("Target university cannot be changed after it has been selected.");
        }

        if (player.TargetUniversityId is null)
        {
            player.TargetUniversityId = universityId;
            await dbContext.SaveChangesAsync(cancellationToken);
            await dbContext.Entry(player).Reference(currentPlayer => currentPlayer.TargetUniversity).LoadAsync(cancellationToken);
        }

        return MapPlayer(player);
    }

    public async Task<PlayerResponseDto> SetAvatarAsync(int id, string avatarId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(avatarId))
        {
            throw new ArgumentException("Avatar id is required.", nameof(avatarId));
        }

        if (avatarId.Length > 100)
        {
            throw new ArgumentException("Avatar id cannot exceed 100 characters.", nameof(avatarId));
        }

        var player = await dbContext.Players
            .Include(currentPlayer => currentPlayer.TargetUniversity)
            .FirstOrDefaultAsync(currentPlayer => currentPlayer.Id == id, cancellationToken);

        if (player is null)
        {
            throw new KeyNotFoundException($"Player with id {id} was not found.");
        }

        player.AvatarId = avatarId;
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapPlayer(player);
    }

    private static PlayerResponseDto MapPlayer(Player player)
    {
        var targetUniversity = player.TargetUniversity;
        var isTargetUnlocked = targetUniversity is not null && player.TotalExp >= targetUniversity.ExpRequired;

        return new PlayerResponseDto
        {
            Id = player.Id,
            Name = player.Name,
            AvatarId = player.AvatarId,
            TotalExp = player.TotalExp,
            TargetUniversityId = player.TargetUniversityId,
            TargetUniversity = targetUniversity is null
                ? null
                : new UniversitySummaryDto
                {
                    Id = targetUniversity.Id,
                    Name = targetUniversity.Name,
                    ShortName = targetUniversity.ShortName,
                    ExpRequired = targetUniversity.ExpRequired
                },
            IsTargetUnlocked = isTargetUnlocked
        };
    }
}

using EnglishRpg.Api.Dtos;

namespace EnglishRpg.Api.Services;

public interface IPlayerService
{
    Task<PlayerResponseDto> GetPlayerByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<PlayerProfileDto> GetPlayerProfileAsync(int id, CancellationToken cancellationToken = default);
    Task<PlayerResponseDto> SetTargetUniversityAsync(int id, int universityId, CancellationToken cancellationToken = default);
    Task<PlayerResponseDto> SetAvatarAsync(int id, string avatarId, CancellationToken cancellationToken = default);
}

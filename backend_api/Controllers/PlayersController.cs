using EnglishRpg.Api.Dtos;
using EnglishRpg.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace EnglishRpg.Api.Controllers;

[ApiController]
[Route("api/players")]
public class PlayersController(IPlayerService playerService) : ControllerBase
{
    [HttpPost("login")]
    public ActionResult Login()
    {
        return StatusCode(410, new { message = "Đăng nhập bằng tài khoản và mật khẩu tại /api/auth/login." });
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<PlayerResponseDto>> GetById(int id, CancellationToken cancellationToken)
    {
        try
        {
            var player = await playerService.GetPlayerByIdAsync(id, cancellationToken);
            return Ok(player);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpGet("{id:int}/profile")]
    public async Task<ActionResult<PlayerProfileDto>> GetProfile(int id, CancellationToken cancellationToken)
    {
        try
        {
            var profile = await playerService.GetPlayerProfileAsync(id, cancellationToken);
            return Ok(profile);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpGet("{id:int}/history")]
    public async Task<ActionResult<List<PlayerHistoryDto>>> GetHistory(int id, CancellationToken cancellationToken)
    {
        var history = await playerService.GetPlayerHistoryAsync(id, cancellationToken);
        return Ok(history);
    }

    [HttpPut("{id:int}/target")]
    public async Task<ActionResult<PlayerResponseDto>> SetTarget(int id, [FromBody] SetPlayerTargetRequest request, CancellationToken cancellationToken)
    {
        if (request is null)
        {
            return BadRequest(new { message = "Request body is required." });
        }

        try
        {
            var player = await playerService.SetTargetUniversityAsync(id, request.UniversityId, cancellationToken);
            return Ok(player);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPut("{id:int}/avatar")]
    public async Task<ActionResult<PlayerResponseDto>> SetAvatar(int id, [FromBody] SetPlayerAvatarRequest request, CancellationToken cancellationToken)
    {
        if (request is null)
        {
            return BadRequest(new { message = "Request body is required." });
        }

        try
        {
            var player = await playerService.SetAvatarAsync(id, request.AvatarId, cancellationToken);
            return Ok(player);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}

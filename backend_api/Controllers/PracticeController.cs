using EnglishRpg.Api.Services;
using Microsoft.AspNetCore.Mvc;
using EnglishRpg.Api.Data;
using EnglishRpg.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace EnglishRpg.Api.Controllers;

[ApiController]
[Route("api/practice")]
public sealed class PracticeController(AppDbContext db) : ControllerBase
{
    [HttpGet("progress")]
    public async Task<IActionResult> Progress(CancellationToken ct) {
        var playerId = User.PlayerId();
        return Ok(await db.PracticeRecords.Where(r => r.PlayerId == playerId)
            .ToDictionaryAsync(r => r.QuestionId, r => r.IsCorrect, ct));
    }
    [HttpGet("topics")]
    public IActionResult Topics() => Ok(PracticeBank.Topics.Select(topic => new {
        topic.Id, topic.Name, topic.Lesson,
        questionCount = PracticeBank.Items.Count(q => q.TopicId == topic.Id)
    }));

    // No correct answer or explanation is returned before submission.
    [HttpGet("questions")]
    public IActionResult Questions([FromQuery] string? topicId)
    {
        if (topicId is not null && !PracticeBank.Topics.Any(t => t.Id == topicId))
            return BadRequest(new { detail = "Chủ đề không tồn tại." });
        return Ok(PracticeBank.Items.Where(q => topicId is null || q.TopicId == topicId)
            .Select(q => new { q.Id, q.TopicId, q.Content, q.Options }));
    }

    public sealed record AnswerRequest(string? QuestionId, int SelectedIndex);

    [HttpPost("answer")]
    public async Task<IActionResult> Answer(AnswerRequest request, CancellationToken ct)
    {
        var question = PracticeBank.Items.FirstOrDefault(q => q.Id == request.QuestionId);
        if (question is null) return NotFound(new { detail = "Câu hỏi không tồn tại." });
        if (request.SelectedIndex is < 0 or > 3)
            return BadRequest(new { detail = "Đáp án phải từ 0 đến 3." });
        var playerId = User.PlayerId();
        var record = await db.PracticeRecords.FindAsync([playerId, question.Id], ct);
        if (record is null) { record = new PracticeRecord {PlayerId = playerId, QuestionId = question.Id}; db.PracticeRecords.Add(record); }
        record.IsCorrect = request.SelectedIndex == question.CorrectIndex;
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateException) { return Conflict(new {message = "Kết quả vừa được cập nhật ở thiết bị khác. Hãy thử lại."}); }
        return Ok(new { isCorrect = request.SelectedIndex == question.CorrectIndex,
            question.CorrectIndex, question.Explanation });
    }
}

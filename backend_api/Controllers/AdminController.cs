using EnglishRpg.Api.Data;
using EnglishRpg.Api.Dtos;
using EnglishRpg.Api.Models;
using EnglishRpg.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EnglishRpg.Api.Controllers;

[ApiController]
[Route("api/admin/questions")]
[Authorize(Roles = "Admin")]
public sealed class AdminController(AppDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<AdminQuestionDto>>> GetQuestions(CancellationToken cancellationToken)
    {
        var questions = await dbContext.Questions
            .AsNoTracking()
            .OrderBy(question => question.StageId)
            .ThenBy(question => question.OrderNo)
            .ToListAsync(cancellationToken);

        return Ok(questions.Select(ToDto).ToList());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<AdminQuestionDto>> GetQuestion(int id, CancellationToken cancellationToken)
    {
        var question = await dbContext.Questions
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.Id == id, cancellationToken);

        return question is null ? NotFound() : Ok(ToDto(question));
    }

    [HttpPost]
    public async Task<ActionResult<AdminQuestionDto>> CreateQuestion(
        SaveQuestionRequest request,
        CancellationToken cancellationToken)
    {
        if (!await dbContext.Stages.AnyAsync(stage => stage.Id == request.StageId, cancellationToken))
        {
            return NotFound(new { message = $"Stage with id {request.StageId} was not found." });
        }

        var orderNo = await dbContext.Questions
            .Where(question => question.StageId == request.StageId)
            .Select(question => (int?)question.OrderNo)
            .MaxAsync(cancellationToken) ?? 0;

        var question = new Question
        {
            StageId = request.StageId,
            OrderNo = orderNo + 1,
            Content = request.Content,
            OptionA = request.OptionA,
            OptionB = request.OptionB,
            OptionC = request.OptionC,
            OptionD = request.OptionD,
            CorrectOption = request.CorrectOption.ToUpperInvariant(),
            Hint1 = request.Hint1,
            Hint2 = request.Hint2,
            Explanation = request.Explanation
        };
        dbContext.Questions.Add(question);
        await dbContext.SaveChangesAsync(cancellationToken);

        return CreatedAtAction(nameof(GetQuestion), new { id = question.Id }, ToDto(question));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<AdminQuestionDto>> UpdateQuestion(
        int id,
        SaveQuestionRequest request,
        CancellationToken cancellationToken)
    {
        var question = await dbContext.Questions
            .FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
        if (question is null)
        {
            return NotFound();
        }

        // Used questions are immutable versions: edits publish a replacement.
        if (await dbContext.AttemptQuestions.AnyAsync(a => a.QuestionId == id, cancellationToken))
        {
            await using var revisionTransaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
            question.IsArchived = true;
            question.ModerationNote = "Đã có phiên bản mới; giữ nguyên kết quả lịch sử.";
            await dbContext.SaveChangesAsync(cancellationToken);
            var replacement = await CreateQuestion(request, cancellationToken);
            if (replacement.Result is CreatedAtActionResult) await revisionTransaction.CommitAsync(cancellationToken);
            return replacement;
        }

        if (!await dbContext.Stages.AnyAsync(stage => stage.Id == request.StageId, cancellationToken))
        {
            return NotFound(new { message = $"Stage with id {request.StageId} was not found." });
        }

        if (question.StageId != request.StageId)
        {
            var orderNo = await dbContext.Questions
                .Where(item => item.StageId == request.StageId)
                .Select(item => (int?)item.OrderNo)
                .MaxAsync(cancellationToken) ?? 0;
            question.OrderNo = orderNo + 1;
            question.StageId = request.StageId;
        }

        question.Content = request.Content;
        question.OptionA = request.OptionA;
        question.OptionB = request.OptionB;
        question.OptionC = request.OptionC;
        question.OptionD = request.OptionD;
        question.CorrectOption = request.CorrectOption.ToUpperInvariant();
        question.Hint1 = request.Hint1;
        question.Hint2 = request.Hint2;
        question.Explanation = request.Explanation;

        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(ToDto(question));
    }

    [HttpGet("{id:int}/impact")]
    public async Task<IActionResult> Impact(int id, CancellationToken ct)
    {
        var question = await dbContext.Questions.FindAsync([id], ct);
        if (question == null) return NotFound();
        var used = dbContext.StageAttempts.Where(a => a.AttemptQuestions.Any(q => q.QuestionId == id));
        return Ok(new {
            attempts = await used.CountAsync(ct),
            completed = await used.CountAsync(a => a.Status == StageAttemptStatus.Passed || a.Status == StageAttemptStatus.Failed, ct),
            activeQuestions = await dbContext.Questions.CountAsync(q => q.StageId == question.StageId && !q.IsArchived, ct),
            requiredQuestions = await dbContext.Stages.Where(s => s.Id == question.StageId).Select(s => s.QuestionCount).SingleAsync(ct)
        });
    }

    [HttpPost("{id:int}/resolve")]
    public async Task<IActionResult> Resolve(int id, ResolveQuestionRequest request, CancellationToken ct)
    {
        if (request.Mode == "correct" && request.CorrectOption == null)
            return BadRequest(new { message = "Hãy chọn đáp án đúng mới." });
        await using var transaction = await dbContext.Database.BeginTransactionAsync(ct);
        var question = await dbContext.Questions.SingleOrDefaultAsync(q => q.Id == id, ct);
        if (question == null) return NotFound();
        // Repeat requests have no additional reward or duplicate replacement.
        if (question.IsVoided || (request.Mode == "correct" && question.CorrectionOption == request.CorrectOption!.ToUpperInvariant()))
            return Ok(new { attempts = 0, exp = 0, message = "Điều chỉnh này đã được áp dụng." });
        question.IsArchived = true;
        question.ModerationNote = $"{DateTime.UtcNow:O} • {User.Identity!.Name} • {request.Mode}: {request.Reason}";
        if (request.Mode == "correct")
        {
            question.CorrectionOption = request.CorrectOption!.ToUpperInvariant();
            var nextOrder = await dbContext.Questions.Where(q => q.StageId == question.StageId).MaxAsync(q => q.OrderNo, ct) + 1;
            dbContext.Questions.Add(new Question {
                StageId = question.StageId, OrderNo = nextOrder, Content = question.Content,
                OptionA = question.OptionA, OptionB = question.OptionB, OptionC = question.OptionC, OptionD = question.OptionD,
                CorrectOption = question.CorrectionOption, Hint1 = question.Hint1, Hint2 = question.Hint2, Explanation = question.Explanation
            });
        }
        if (request.Mode == "void") question.IsVoided = true;
        await dbContext.SaveChangesAsync(ct);
        var result = request.Mode == "retire" ? (Attempts: 0, Exp: 0) : await QuestionCompensation.ReconcileAsync(dbContext, id, ct);
        await transaction.CommitAsync(ct);
        return Ok(new { attempts = result.Attempts, exp = result.Exp, message = "Đã xử lý. Chỉ bù quyền lợi, không thu hồi EXP/ải/huy hiệu." });
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeleteQuestion(int id, CancellationToken cancellationToken)
    {
        var question = await dbContext.Questions
            .FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
        if (question is null)
        {
            return NotFound();
        }

        var isUsedInAttempt = await dbContext.AttemptQuestions
            .AnyAsync(item => item.QuestionId == id, cancellationToken) ||
            await dbContext.AttemptAnswers.AnyAsync(item => item.QuestionId == id, cancellationToken);
        if (isUsedInAttempt)
        {
            return Conflict(new { message = "Question cannot be deleted because it is referenced by a player attempt." });
        }

        dbContext.Questions.Remove(question);
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private static AdminQuestionDto ToDto(Question question) => new(
        question.Id,
        question.StageId,
        question.Content,
        question.OptionA,
        question.OptionB,
        question.OptionC,
        question.OptionD,
        question.CorrectOption,
        question.Hint1,
        question.Hint2,
        question.Explanation,
        question.IsArchived,
        question.IsVoided,
        question.CorrectionOption,
        question.ModerationNote);
}

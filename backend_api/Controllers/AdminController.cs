using EnglishRpg.Api.Data;
using EnglishRpg.Api.Dtos;
using EnglishRpg.Api.Models;
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
        question.Explanation);
}

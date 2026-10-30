using EnglishRpg.Api.Data;
using EnglishRpg.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace EnglishRpg.Api.Services;

public static class QuestionCompensation
{
    public static void ApplyAnswers(StageAttempt attempt)
    {
        foreach (var item in attempt.AttemptQuestions)
        {
            var question = item.Question;
            var answer = attempt.AttemptAnswers.FirstOrDefault(a => a.QuestionId == item.QuestionId);
            if (answer == null && question.IsVoided)
            {
                answer = new AttemptAnswer { AttemptId = attempt.Id, QuestionId = question.Id, IsCorrect = true };
                attempt.AttemptAnswers.Add(answer);
            }
            if (answer == null) continue;
            if (question.IsVoided || (question.CorrectionOption != null && answer.SelectedOption == question.CorrectionOption))
            {
                answer.IsCorrect = true;
                answer.ExpDelta = attempt.Stage.Type == StageType.Normal ? attempt.Stage.ExpPerCorrect : 0;
                answer.UsedNextHint = false;
            }
        }
        attempt.CorrectCount = attempt.AttemptAnswers.Count(a => a.IsCorrect);
    }

    public static async Task<(int Attempts, int Exp)> ReconcileAsync(AppDbContext db, int questionId, CancellationToken ct)
    {
        var attempts = await db.StageAttempts
            .Include(a => a.Stage).Include(a => a.Player)
            .Include(a => a.AttemptQuestions).ThenInclude(q => q.Question)
            .Include(a => a.AttemptAnswers)
            .Where(a => a.AttemptQuestions.Any(q => q.QuestionId == questionId) &&
                (a.Status == StageAttemptStatus.Passed || a.Status == StageAttemptStatus.Failed || a.Status == StageAttemptStatus.InProgress))
            .OrderBy(a => a.Id).ToListAsync(ct);
        var total = 0; var changed = 0;
        foreach (var attempt in attempts)
        {
            // Unfinished attempts are adjusted at submission/finish, never prematurely awarded.
            if (attempt.Status == StageAttemptStatus.InProgress) continue;
            var oldCorrect = attempt.CorrectCount;
            var oldStatus = attempt.Status;
            ApplyAnswers(attempt);
            var progress = db.PlayerStageProgress.Local.FirstOrDefault(p => p.PlayerId == attempt.PlayerId && p.StageId == attempt.StageId)
                ?? await db.PlayerStageProgress.SingleOrDefaultAsync(p => p.PlayerId == attempt.PlayerId && p.StageId == attempt.StageId, ct);
            if (progress == null)
            {
                progress = new PlayerStageProgress { PlayerId = attempt.PlayerId, StageId = attempt.StageId };
                db.PlayerStageProgress.Add(progress);
            }
            // Respect timeout failures; preserve an existing pass regardless of later corrections.
            var passes = attempt.Status == StageAttemptStatus.Passed ||
                (attempt.CorrectCount >= attempt.Stage.PassCorrect && attempt.FinishedAt <= attempt.ExpiresAt);
            if (passes)
            {
                attempt.Status = StageAttemptStatus.Passed;
                progress.IsCompleted = true;
                progress.FirstClearedAt ??= DateTime.UtcNow;
            }
            progress.BestCorrectCount = Math.Max(progress.BestCorrectCount, attempt.CorrectCount);
            var desired = attempt.Stage.Type == StageType.Normal
                ? Math.Max(0, attempt.AttemptAnswers.Sum(a => a.ExpDelta))
                : passes && !progress.BossRewardClaimed ? attempt.Stage.BonusExp : attempt.ExpEarned;
            if (attempt.Stage.Type == StageType.Boss && passes) progress.BossRewardClaimed = true;
            var delta = Math.Max(0, desired - attempt.ExpEarned);
            attempt.ExpEarned += delta;
            attempt.CompensationExp += delta;
            attempt.Player.TotalExp += delta;
            total += delta;
            if (delta > 0 || oldCorrect != attempt.CorrectCount || oldStatus != attempt.Status) changed++;
            var names = new List<string>();
            if (passes && attempt.Stage.Type == StageType.Normal && attempt.Stage.OrderNo == 1) names.Add("Chiến binh tập sự");
            if (attempt.AttemptQuestions.Count == 10 && attempt.CorrectCount == 10) names.Add("Bất bại");
            if (passes && attempt.Stage.Type == StageType.Boss) names.Add("Kẻ chinh phục");
            foreach (var badge in await db.Badges.Where(b => names.Contains(b.Name)).ToListAsync(ct))
            {
                if (!db.PlayerBadges.Local.Any(b => b.PlayerId == attempt.PlayerId && b.BadgeId == badge.Id) &&
                    !await db.PlayerBadges.AnyAsync(b => b.PlayerId == attempt.PlayerId && b.BadgeId == badge.Id, ct))
                    db.PlayerBadges.Add(new PlayerBadge { PlayerId = attempt.PlayerId, BadgeId = badge.Id });
            }
        }
        await db.SaveChangesAsync(ct);
        return (changed, total);
    }
}

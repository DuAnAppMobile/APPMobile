using Microsoft.EntityFrameworkCore;

namespace EnglishRpg.Api.Data;

// Existing demo databases were created with EnsureCreated, without migration history.
// Add only missing columns; preserve accounts, attempts and existing migration state.
public static class ModerationSchema
{
    public static async Task UpgradeAsync(AppDbContext db)
    {
        if (!db.Database.IsSqlite()) return;
        await db.Database.EnsureCreatedAsync();
        await db.Database.OpenConnectionAsync();
        try
        {
            foreach (var table in new[] { "Questions", "StageAttempts" })
            {
                var columns = new HashSet<string>();
                using (var command = db.Database.GetDbConnection().CreateCommand())
                {
                    command.CommandText = $"PRAGMA table_info(\"{table}\")";
                    await using var reader = await command.ExecuteReaderAsync();
                    while (await reader.ReadAsync()) columns.Add(reader.GetString(1));
                }
                var additions = table == "Questions"
                    ? new Dictionary<string, string> { ["IsArchived"] = "INTEGER NOT NULL DEFAULT 0", ["IsVoided"] = "INTEGER NOT NULL DEFAULT 0", ["CorrectionOption"] = "TEXT NULL", ["ModerationNote"] = "TEXT NULL" }
                    : new Dictionary<string, string> { ["CompensationExp"] = "INTEGER NOT NULL DEFAULT 0" };
                foreach (var column in additions.Where(c => !columns.Contains(c.Key)))
                {
                    using var command = db.Database.GetDbConnection().CreateCommand();
                    command.CommandText = $"ALTER TABLE \"{table}\" ADD COLUMN \"{column.Key}\" {column.Value}";
                    await command.ExecuteNonQueryAsync();
                }
            }
        }
        finally { await db.Database.CloseConnectionAsync(); }
    }
}

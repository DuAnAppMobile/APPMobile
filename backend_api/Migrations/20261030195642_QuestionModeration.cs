using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EnglishRpg.Api.Migrations
{
    /// <inheritdoc />
    public partial class QuestionModeration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CompensationExp",
                table: "StageAttempts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "CorrectionOption",
                table: "Questions",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsArchived",
                table: "Questions",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsVoided",
                table: "Questions",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "ModerationNote",
                table: "Questions",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CompensationExp",
                table: "StageAttempts");

            migrationBuilder.DropColumn(
                name: "CorrectionOption",
                table: "Questions");

            migrationBuilder.DropColumn(
                name: "IsArchived",
                table: "Questions");

            migrationBuilder.DropColumn(
                name: "IsVoided",
                table: "Questions");

            migrationBuilder.DropColumn(
                name: "ModerationNote",
                table: "Questions");
        }
    }
}

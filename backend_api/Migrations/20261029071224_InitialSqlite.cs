using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EnglishRpg.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialSqlite : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Badges",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: false),
                    IconUrl = table.Column<string>(type: "TEXT", maxLength: 2048, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Badges", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Stages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    OrderNo = table.Column<int>(type: "INTEGER", nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    Type = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    QuestionCount = table.Column<int>(type: "INTEGER", nullable: false),
                    PassCorrect = table.Column<int>(type: "INTEGER", nullable: false),
                    TimeLimitSeconds = table.Column<int>(type: "INTEGER", nullable: true),
                    ExpPerCorrect = table.Column<int>(type: "INTEGER", nullable: false),
                    BonusExp = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Stages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Universities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    ShortName = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    ExpRequired = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Universities", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Questions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    StageId = table.Column<int>(type: "INTEGER", nullable: false),
                    OrderNo = table.Column<int>(type: "INTEGER", nullable: false),
                    Content = table.Column<string>(type: "TEXT", nullable: false),
                    OptionA = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: false),
                    OptionB = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: false),
                    OptionC = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: false),
                    OptionD = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: false),
                    CorrectOption = table.Column<string>(type: "TEXT", maxLength: 1, nullable: false),
                    Hint1 = table.Column<string>(type: "TEXT", nullable: true),
                    Hint2 = table.Column<string>(type: "TEXT", nullable: true),
                    Explanation = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Questions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Questions_Stages_StageId",
                        column: x => x.StageId,
                        principalTable: "Stages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Players",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    AvatarId = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false, defaultValue: "default_avatar"),
                    TargetUniversityId = table.Column<int>(type: "INTEGER", nullable: true),
                    TotalExp = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Players", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Players_Universities_TargetUniversityId",
                        column: x => x.TargetUniversityId,
                        principalTable: "Universities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Accounts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Username = table.Column<string>(type: "TEXT", maxLength: 32, nullable: false),
                    PasswordHash = table.Column<string>(type: "TEXT", maxLength: 512, nullable: false),
                    PlayerId = table.Column<int>(type: "INTEGER", nullable: false),
                    FailedLogins = table.Column<int>(type: "INTEGER", nullable: false),
                    LockedUntil = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Accounts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Accounts_Players_PlayerId",
                        column: x => x.PlayerId,
                        principalTable: "Players",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PlayerBadges",
                columns: table => new
                {
                    PlayerId = table.Column<int>(type: "INTEGER", nullable: false),
                    BadgeId = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PlayerBadges", x => new { x.PlayerId, x.BadgeId });
                    table.ForeignKey(
                        name: "FK_PlayerBadges_Badges_BadgeId",
                        column: x => x.BadgeId,
                        principalTable: "Badges",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PlayerBadges_Players_PlayerId",
                        column: x => x.PlayerId,
                        principalTable: "Players",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PlayerStageProgress",
                columns: table => new
                {
                    PlayerId = table.Column<int>(type: "INTEGER", nullable: false),
                    StageId = table.Column<int>(type: "INTEGER", nullable: false),
                    IsCompleted = table.Column<bool>(type: "INTEGER", nullable: false),
                    FirstClearedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    BestCorrectCount = table.Column<int>(type: "INTEGER", nullable: false),
                    BossRewardClaimed = table.Column<bool>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PlayerStageProgress", x => new { x.PlayerId, x.StageId });
                    table.ForeignKey(
                        name: "FK_PlayerStageProgress_Players_PlayerId",
                        column: x => x.PlayerId,
                        principalTable: "Players",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PlayerStageProgress_Stages_StageId",
                        column: x => x.StageId,
                        principalTable: "Stages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PracticeRecords",
                columns: table => new
                {
                    PlayerId = table.Column<int>(type: "INTEGER", nullable: false),
                    QuestionId = table.Column<string>(type: "TEXT", maxLength: 32, nullable: false),
                    IsCorrect = table.Column<bool>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PracticeRecords", x => new { x.PlayerId, x.QuestionId });
                    table.ForeignKey(
                        name: "FK_PracticeRecords_Players_PlayerId",
                        column: x => x.PlayerId,
                        principalTable: "Players",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "StageAttempts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PlayerId = table.Column<int>(type: "INTEGER", nullable: false),
                    StageId = table.Column<int>(type: "INTEGER", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    FinishedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Status = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    CorrectCount = table.Column<int>(type: "INTEGER", nullable: false),
                    ExpEarned = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StageAttempts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StageAttempts_Players_PlayerId",
                        column: x => x.PlayerId,
                        principalTable: "Players",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StageAttempts_Stages_StageId",
                        column: x => x.StageId,
                        principalTable: "Stages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "LoginSessions",
                columns: table => new
                {
                    TokenHash = table.Column<string>(type: "TEXT", maxLength: 64, nullable: false),
                    AccountId = table.Column<int>(type: "INTEGER", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LoginSessions", x => x.TokenHash);
                    table.ForeignKey(
                        name: "FK_LoginSessions_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AttemptAnswers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    AttemptId = table.Column<int>(type: "INTEGER", nullable: false),
                    QuestionId = table.Column<int>(type: "INTEGER", nullable: false),
                    SelectedOption = table.Column<string>(type: "TEXT", maxLength: 1, nullable: true),
                    IsCorrect = table.Column<bool>(type: "INTEGER", nullable: false),
                    ShownHint1 = table.Column<bool>(type: "INTEGER", nullable: false),
                    UsedNextHint = table.Column<bool>(type: "INTEGER", nullable: false),
                    ExpDelta = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AttemptAnswers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AttemptAnswers_Questions_QuestionId",
                        column: x => x.QuestionId,
                        principalTable: "Questions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AttemptAnswers_StageAttempts_AttemptId",
                        column: x => x.AttemptId,
                        principalTable: "StageAttempts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "AttemptQuestions",
                columns: table => new
                {
                    AttemptId = table.Column<int>(type: "INTEGER", nullable: false),
                    QuestionId = table.Column<int>(type: "INTEGER", nullable: false),
                    OrderNo = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AttemptQuestions", x => new { x.AttemptId, x.QuestionId });
                    table.ForeignKey(
                        name: "FK_AttemptQuestions_Questions_QuestionId",
                        column: x => x.QuestionId,
                        principalTable: "Questions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AttemptQuestions_StageAttempts_AttemptId",
                        column: x => x.AttemptId,
                        principalTable: "StageAttempts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_PlayerId",
                table: "Accounts",
                column: "PlayerId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_Username",
                table: "Accounts",
                column: "Username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AttemptAnswers_AttemptId",
                table: "AttemptAnswers",
                column: "AttemptId");

            migrationBuilder.CreateIndex(
                name: "IX_AttemptAnswers_QuestionId",
                table: "AttemptAnswers",
                column: "QuestionId");

            migrationBuilder.CreateIndex(
                name: "IX_AttemptQuestions_QuestionId",
                table: "AttemptQuestions",
                column: "QuestionId");

            migrationBuilder.CreateIndex(
                name: "IX_LoginSessions_AccountId",
                table: "LoginSessions",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_PlayerBadges_BadgeId",
                table: "PlayerBadges",
                column: "BadgeId");

            migrationBuilder.CreateIndex(
                name: "IX_Players_Name",
                table: "Players",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Players_TargetUniversityId",
                table: "Players",
                column: "TargetUniversityId");

            migrationBuilder.CreateIndex(
                name: "IX_PlayerStageProgress_StageId",
                table: "PlayerStageProgress",
                column: "StageId");

            migrationBuilder.CreateIndex(
                name: "IX_Questions_StageId",
                table: "Questions",
                column: "StageId");

            migrationBuilder.CreateIndex(
                name: "IX_StageAttempts_PlayerId",
                table: "StageAttempts",
                column: "PlayerId");

            migrationBuilder.CreateIndex(
                name: "IX_StageAttempts_StageId",
                table: "StageAttempts",
                column: "StageId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AttemptAnswers");

            migrationBuilder.DropTable(
                name: "AttemptQuestions");

            migrationBuilder.DropTable(
                name: "LoginSessions");

            migrationBuilder.DropTable(
                name: "PlayerBadges");

            migrationBuilder.DropTable(
                name: "PlayerStageProgress");

            migrationBuilder.DropTable(
                name: "PracticeRecords");

            migrationBuilder.DropTable(
                name: "Questions");

            migrationBuilder.DropTable(
                name: "StageAttempts");

            migrationBuilder.DropTable(
                name: "Accounts");

            migrationBuilder.DropTable(
                name: "Badges");

            migrationBuilder.DropTable(
                name: "Stages");

            migrationBuilder.DropTable(
                name: "Players");

            migrationBuilder.DropTable(
                name: "Universities");
        }
    }
}

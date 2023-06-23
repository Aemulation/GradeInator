defmodule GradeInator.Repo.Migrations.CreateSubmissionScores do
  use Ecto.Migration

  def change do
    create table(:submission_scores) do
      add :submission_id, references(:submissions, on_delete: :delete_all), null: false
      add :assignment_score_id, references(:assignment_scores, on_delete: :delete_all), null: false
      add :value, :string, null: false

      timestamps(default: fragment("now()"))
    end

    create unique_index(:submission_scores, [:submission_id, :assignment_score_id])
  end
end
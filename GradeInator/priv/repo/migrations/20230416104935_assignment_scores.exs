defmodule GradeInator.Repo.Migrations.AssignmentScores do
  use Ecto.Migration

  alias GradeInator.Repo
  alias GradeInator.AssignmentList.AssignmentScoreType

  def change do
    create table(:assignment_score_types) do
      add :type, :string, null: false
    end

    flush()
    Repo.insert(%AssignmentScoreType{type: "string"})
    Repo.insert(%AssignmentScoreType{type: "number"})

    create table(:assignment_scores) do
      add :assignment_id, references(:assignments, on_delete: :delete_all), null: false
      add :key, :string, null: false

      add :assignment_score_type_id, references(:assignment_score_types, on_delete: :delete_all),
        null: false

      add :visible_to_public, :boolean, null: false
    end

    create unique_index(:assignment_scores, [:assignment_id, :key])
  end
end
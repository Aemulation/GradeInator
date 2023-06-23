defmodule GradeInator.Repo.Migrations.CreateSubmissions do
  use Ecto.Migration

  def change do
    create table(:submissions) do
      add :assignment_id, references(:assignments, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :group_id, references(:groups, on_delete: :nothing), null: true
      add :state_id, references(:submission_states, on_delete: :nothing), null: false
      add :result, :string, default: nil

      timestamps()
    end

    create index(:submissions, [:assignment_id])
    create index(:submissions, [:state_id])
  end
end

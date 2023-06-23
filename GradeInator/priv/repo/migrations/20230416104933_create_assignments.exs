defmodule GradeInator.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :assignment_name, :string
      add :assignment_description, :string
      add :visible, :boolean, default: false, null: false
      add :deadline, :naive_datetime

      timestamps()
    end
  end
end

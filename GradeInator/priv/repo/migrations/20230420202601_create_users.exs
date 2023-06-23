defmodule GradeInator.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :role, :string, null: false

      add :group_id, references(:groups)

      timestamps()
    end
  end
end

defmodule GradeInator.Repo.Migrations.RequiredSubmissionFiles do
  use Ecto.Migration

  def change do
    create table(:required_submission_files) do
      add :assignment_id, references(:assignments, on_delete: :delete_all), null: false
      add :file_name, :string
    end

    create unique_index(:required_submission_files, [:assignment_id, :file_name])
  end
end

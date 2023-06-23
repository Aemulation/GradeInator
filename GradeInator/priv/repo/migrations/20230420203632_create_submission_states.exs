defmodule GradeInator.Repo.Migrations.CreateSubmissionStates do
  use Ecto.Migration

  alias GradeInator.Repo
  alias GradeInator.Course.SubmissionState

  def change do
    create table(:submission_states) do
      add :state, :string, null: false
    end

    create unique_index(:submission_states, [:state])

    flush()

    Repo.insert(%SubmissionState{id: 1, state: "ungraded"})
    Repo.insert(%SubmissionState{id: 2, state: "graded"})
    Repo.insert(%SubmissionState{id: 3, state: "run error"})
    Repo.insert(%SubmissionState{id: 4, state: "grade error"})
    Repo.insert(%SubmissionState{id: 5, state: "cancelled"})
    Repo.insert(%SubmissionState{id: 6, state: "timedout"})
  end
end

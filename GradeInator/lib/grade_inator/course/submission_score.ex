defmodule GradeInator.Course.SubmissionScore do
  use Ecto.Schema
  import Ecto.Changeset

  alias GradeInator.AssignmentList.AssignmentScore
  alias GradeInator.Course.Submission

  schema "submission_scores" do
    belongs_to(:submission, Submission)
    belongs_to(:assignment_score, AssignmentScore)
    field :value, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(submission_scores, attrs) do
    submission_scores
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end
end

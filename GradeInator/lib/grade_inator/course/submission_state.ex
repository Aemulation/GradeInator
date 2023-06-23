defmodule GradeInator.Course.SubmissionState do
  use Ecto.Schema
  import Ecto.Changeset

  schema "submission_states" do
    field :state, :string
  end

  @doc false
  def changeset(submission_state, attrs) do
    submission_state
    |> cast(attrs, [:state])
    |> validate_required([:state])
  end
end

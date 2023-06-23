defmodule GradeInator.AssignmentList.AssignmentScoreType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assignment_score_types" do
    field(:type, :string)
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end

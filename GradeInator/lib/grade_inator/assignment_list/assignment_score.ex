defmodule GradeInator.AssignmentList.AssignmentScore do
  use Ecto.Schema
  import Ecto.Changeset

  # alias GradeInator.AssignmentList.AssignmentScoreType
  alias GradeInator.AssignmentList.Assignment

  schema "assignment_scores" do
    belongs_to(:assignment, Assignment)

    field(:key, :string)

    field(:visible_to_public, :boolean)

    field(:assignment_score_type_id, :id)
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:key, :visible_to_public, :assignment_score_type_id])
    |> cast_assoc(:assignment)
    |> validate_required([:key, :visible_to_public])
    |> unique_constraint([:key, :assignment], name: "assignment_scores_assignment_id_key_index")
  end
end

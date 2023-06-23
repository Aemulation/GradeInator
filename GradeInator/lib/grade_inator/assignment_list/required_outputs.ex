defmodule GradeInator.AssignmentList.RequiredOutputs do
  use Ecto.Schema
  import Ecto.Changeset

  schema "required_outputs" do
    field(:assignment_id, :id)
    field(:key, :string)
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:key])
    |> validate_required([:key])
  end
end

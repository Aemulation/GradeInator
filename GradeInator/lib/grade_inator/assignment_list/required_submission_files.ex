defmodule GradeInator.AssignmentList.RequiredSubmissionFile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "required_submission_files" do
    field(:assignment_id, :id)
    field(:file_name, :string)

    field(:position, :integer, virtual: true)
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:file_name])
    |> validate_required([:file_name])
    |> unique_constraint([:file_name, :assignment_id],
      name: "required_submission_files_assignment_id_file_name_index"
    )
  end
end

defmodule GradeInator.AssignmentList.Assignment do
  use Ecto.Schema
  import Ecto.Changeset

  alias GradeInator.AssignmentList.RequiredSubmissionFile
  alias GradeInator.AssignmentList.AssignmentScore

  schema "assignments" do
    field(:assignment_name, :string)
    field(:assignment_description, :string)
    field(:visible, :boolean, default: true)
    field(:deadline, :utc_datetime)

    has_many(:required_submission_files, RequiredSubmissionFile,
      on_replace: :delete,
      on_delete: :delete_all,
      preload_order: [asc: :id]
    )

    has_many(:assignment_scores, AssignmentScore,
      on_replace: :delete,
      on_delete: :delete_all,
      preload_order: [asc: :id]
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:assignment_name, :assignment_description, :visible, :deadline])
    |> cast_assoc(:required_submission_files,
      with: &RequiredSubmissionFile.changeset/2,
      sort_param: :required_submission_files_sort,
      drop_param: :required_submission_files_drop
    )
    |> cast_assoc(:assignment_scores,
      with: &AssignmentScore.changeset/2,
      sort_param: :assignment_scores_sort,
      drop_param: :assignment_scores_drop
    )
    |> validate_required([:assignment_name, :visible, :deadline])
  end
end

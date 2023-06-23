defmodule GradeInator.Course.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  alias GradeInator.Course.SubmissionScore
  alias GradeInator.Course.User
  alias GradeInator.Course.SubmissionState
  alias GradeInator.Course.Group
  alias GradeInator.AssignmentList.Assignment
  alias GradeInator.SubmissionList

  schema "submissions" do
    belongs_to(:assignment, Assignment)
    belongs_to(:user, User, on_replace: :update)
    belongs_to(:group, Group)
    belongs_to(:state, SubmissionState)
    field(:result, :string, default: nil)

    has_many(:submission_scores, SubmissionScore)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:assignment_id])
    |> put_assoc(:state, attrs[:state])
    |> put_assoc(:group, attrs[:group])
    |> validate_required([:assignment_id, :user, :state])
  end

  def allowed_to_download(_submission_id, %User{role: "teacher"}) do
    true
  end

  def allowed_to_download(_submission_id, %User{role: "ta"}) do
    true
  end

  def allowed_to_download(submission_id, %User{id: user_id, access_token: access_token}) do
    submission = SubmissionList.get_submission!(submission_id)
    {:ok, group} = Group.fetch_using_canvas(access_token)

    case submission.user_id do
      ^user_id ->
        true
      _ -> if submission.group_id == group.id do
        true
      else
        false
      end
    end
  end
end

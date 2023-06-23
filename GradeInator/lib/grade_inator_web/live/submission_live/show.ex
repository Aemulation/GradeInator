defmodule GradeInatorWeb.SubmissionLive.Show do
  use GradeInatorWeb, :live_view

  alias GradeInator.AssignmentList
  alias GradeInator.SubmissionList
  alias GradeInator.Course.Group
  alias GradeInator.Course.User
  alias GradeInator.Course.Submission

  alias GradeInator.Course.Time

  @impl true
  def mount(_params, %{"user" => %User{} = user} = _session, socket) do
    {:ok,
      socket
      |> assign(:user, user)
    }
  end

  defp preload_submission(%Submission{} = submission, %User{role: "teacher"}, _) do
    SubmissionList.preload_submission_private(submission)
  end

  defp preload_submission(%Submission{} = submission, %User{role: "ta"}, _) do
    SubmissionList.preload_submission_private(submission)
  end

  defp preload_submission(%Submission{user_id: submission_user_id} = submission, %User{} = user, nil) do
    case user.id do
      ^submission_user_id -> SubmissionList.preload_submission_private(submission)
      _ -> SubmissionList.preload_submission_public(submission)
    end
  end

  defp preload_submission(%Submission{user_id: submission_user_id} = submission, %User{id: user_id}, %Group{id: group_id}) do
    case user_id do
      ^submission_user_id -> SubmissionList.preload_submission_private(submission)
      _ ->
      case submission.group_id do
        ^group_id -> SubmissionList.preload_submission_private(submission)
        _ -> SubmissionList.preload_submission_public(submission)
      end
    end
  end


  @impl true
  def handle_params(
        %{"submission_id" => submission_id, "assignment_id" => assignment_id},
        _,
        socket
      ) do
    assignment_id = String.to_integer(assignment_id)

    submission = SubmissionList.get_submission!(submission_id)
    {:ok, group} = Group.fetch_using_canvas(socket.assigns.user.access_token)

    submission = preload_submission(submission, socket.assigns.user, group)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:submission, submission)
     |> assign(:assignment, AssignmentList.get_assignment!(assignment_id))}
  end

  defp page_title(:show), do: "Show Submission"
  defp page_title(:edit), do: "Edit Submission"
end

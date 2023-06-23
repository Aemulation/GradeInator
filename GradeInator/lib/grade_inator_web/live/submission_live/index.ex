defmodule GradeInatorWeb.SubmissionLive.Index do
  use GradeInatorWeb, :live_view

  alias GradeInator.AssignmentList
  alias GradeInator.SubmissionList
  alias GradeInator.Course.Submission

  alias GradeInator.Course.Time

  @impl true
  def mount(%{"assignment_id" => assignment_id} = _params, %{"user" => user} = session, socket) do
    submissions =
      SubmissionList.list_submissions(%AssignmentList.Assignment{id: assignment_id}, user)

    {:ok,
     socket
     |> stream(:submissions, submissions)
     |> assign(:user, Map.get(session, "user"))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, %{"assignment_id" => assignment_id}) do
    assignment_id = String.to_integer(assignment_id)
    user = socket.assigns.user

    submission =
      GradeInator.Repo.preload(
        %Submission{assignment_id: assignment_id, user: user},
        assignment: [:required_submission_files]
      )

    socket
    |> assign(:page_title, "New Submission")
    |> assign(:submission, submission)
    |> assign(:assignment, AssignmentList.get_assignment!(assignment_id))
  end

  defp apply_action(socket, :index, %{"assignment_id" => assignment_id}) do
    socket
    |> assign(:page_title, "Listing Submissions")
    |> assign(:assignment, AssignmentList.get_assignment!(assignment_id))
  end

  @impl true
  def handle_info({GradeInatorWeb.SubmissionLive.FormComponent, {:saved, submission}}, socket) do
    {:noreply, stream_insert(socket, :submissions, submission, at: 0)}
  end
end

defmodule GradeInatorWeb.GroupLive.Show do
  use GradeInatorWeb, :live_view

  alias GradeInator.Repo
  alias GradeInator.Course.Group
  alias GradeInator.Course.Submission
  alias GradeInator.AssignmentList

  alias GradeInator.Course.Time

  @impl true
  def mount(%{"assignment_id" => assignment_id} = _params, session, socket) do
    assignment = AssignmentList.get_assignment!(assignment_id)
    user = Map.get(session, "user")

    {:ok,
     socket
     |> assign(:assignment, assignment)
     |> assign(:user, user)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"group_id" => group_id} = _params) do
    group = Repo.get!(Group, group_id) |> Repo.preload(submissions: [:user, :state])

    socket
    |> assign(:group, group)
    |> assign(:page_title, group.name)
  end

  defp apply_action(
         socket,
         :new,
         %{"assignment_id" => assignment_id, "group_id" => group_id} = _params
       ) do
    assignment_id = String.to_integer(assignment_id)
    group = Repo.get!(Group, group_id) |> Repo.preload(submissions: [:user, :state])
    user = socket.assigns.user

    submission =
      Repo.preload(
        %Submission{assignment_id: assignment_id, user: user},
        assignment: [:required_submission_files]
      )

    socket
    |> assign(:group, group)
    |> assign(:submission, submission)
    |> assign(:page_title, group.name)
  end

  # @impl true
  # def handle_info({GradeInatorWeb.SubmissionLive.FormComponent, {:saved, submission}}, socket) do
  #   {:noreply, stream_insert(socket, :submissions, submission, at: 0)}
  # end
end
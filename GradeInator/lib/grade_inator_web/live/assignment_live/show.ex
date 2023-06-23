defmodule GradeInatorWeb.AssignmentLive.Show do
  use GradeInatorWeb, :live_view

  alias GradeInator.Repo
  alias GradeInator.AssignmentList
  alias GradeInator.Course.User
  alias GradeInator.Course.Group

  alias GradeInator.Course.Time

  @impl true
  def mount(_params, %{"user" => %User{role: "teacher"} = user} = _session, socket) do
    groups = Repo.all(Group)

    IO.inspect(Group.get_latest_submission_per_group())

    {:ok,
     socket
     |> assign(:user, user)
     |> stream(:groups, groups)}
  end

  @impl true
  def mount(_params, %{"user" => user} = _session, socket) do
    {:ok, assign(socket, :user, user)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    apply_action(socket, socket.assigns.live_action, params)
  end

  defp apply_action(%{assigns: %{user: %User{role: "teacher"}}} = socket, :show, %{"id" => id}) do
    assignment =
      AssignmentList.get_assignment!(id)
      |> GradeInator.Repo.preload([:assignment_scores])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:assignment, assignment)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    assignment =
      AssignmentList.get_assignment!(id)
      |> GradeInator.Repo.preload([:assignment_scores])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:assignment, assignment)}
  end

  defp apply_action(%{assigns: %{user: %User{role: "teacher"}}} = socket, :edit, %{"id" => id}) do
    assignment =
      AssignmentList.get_assignment!(id)
      |> GradeInator.Repo.preload([:assignment_scores])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:assignment, assignment)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    unauthorized_redirect(socket, id)
  end

  defp unauthorized_redirect(socket, assignment_id) do
    {:noreply,
     socket
     |> put_flash(:error, "unauthorized")
     |> push_patch(to: ~p"/assignments/#{assignment_id}")}
  end

  defp page_title(:show), do: "Show Assignment"
  defp page_title(:edit), do: "Edit Assignment"


  attr :user, User, required: true
  attr :assignment, :list, required: true

  def assignment_list(%{user: %User{role: "teacher"}} = assigns) do
    ~H"""
      <.list>
        <:item title="Assignment name"><%= @assignment.assignment_name %></:item>
        <:item title="Assignment description"><%= @assignment.assignment_description %></:item>
        <:item title="Visible"><%= @assignment.visible %></:item>
        <:item title="Deadline"><%= Time.get_pretty_datetime(@assignment.deadline) %></:item>
      </.list>
    """
  end

  def assignment_list(%{user: %User{role: "ta"}} = assigns) do
    ~H"""
      <.list>
        <:item title="Assignment name"><%= @assignment.assignment_name %></:item>
        <:item title="Assignment description"><%= @assignment.assignment_description %></:item>
        <:item title="Visible"><%= @assignment.visible %></:item>
        <:item title="Deadline"><%= Time.get_pretty_datetime(@assignment.deadline) %></:item>
      </.list>
    """
  end

  def assignment_list(%{user: %User{role: "student"}} = assigns) do
    ~H"""
      <.list>
        <:item title="Assignment name"><%= @assignment.assignment_name %></:item>
        <:item title="Assignment description"><%= @assignment.assignment_description %></:item>
        <:item title="Deadline"><%= Time.get_pretty_datetime(@assignment.deadline) %></:item>
      </.list>
    """
  end
end

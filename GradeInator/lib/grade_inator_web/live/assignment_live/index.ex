defmodule GradeInatorWeb.AssignmentLive.Index do
  use GradeInatorWeb, :live_view

  alias GradeInator.AssignmentList
  alias GradeInator.AssignmentList.Assignment
  alias GradeInator.AssignmentList.AssignmentScore
  alias GradeInator.Course.User

  alias GradeInator.Course.Time

  @impl true
  def mount(_params, %{"user" => %User{role: "student"} = user} = _session, socket) do
    {:ok,
     socket
     |> assign(:user, user)
     |> stream(:assignments, AssignmentList.list_assignments_student())}
  end

  @impl true
  def mount(_params, %{"user" => %User{role: "ta"} = user} = _session, socket) do
    {:ok,
     socket
     |> assign(:user, user)
     |> stream(:assignments, AssignmentList.list_assignments())}
  end

  @impl true
  def mount(_params, %{"user" => %User{role: "teacher"} = user} = _session, socket) do
    {:ok,
     socket
     |> assign(:user, user)
     |> stream(:assignments, AssignmentList.list_assignments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: %{user: %User{role: "teacher"}}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Assignment")
    |> assign(
      :assignment,
      AssignmentList.get_assignment!(id)
    )
  end

  defp apply_action(socket, :edit, _) do
    socket
    |> put_flash(:error, "unauthorized")
    |> push_patch(to: ~p"/assignments/")
  end

  defp apply_action(%{assigns: %{user: %{role: "teacher"}}} = socket, :new, _) do
    socket
    |> assign(:page_title, "New Assignment")
    |> assign(:assignment, %Assignment{assignment_scores: [%AssignmentScore{key: :debug_log, visible_to_public: false, assignment_score_type_id: 1}]})
  end

  defp apply_action(socket, :new, _) do
    socket
    |> put_flash(:error, "unauthorized")
    |> push_patch(to: ~p"/assignments/")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Assignments")
    |> assign(:assignment, nil)
  end

  defp apply_action(socket, :submit, _params) do
    socket
    |> assign(:page_title, "Submit Assignment")
    |> assign(:assignment, nil)
  end

  @impl true
  def handle_info({GradeInatorWeb.AssignmentLive.FormComponent, {:saved, assignment}}, socket) do
    {:noreply, stream_insert(socket, :assignments, assignment)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{user: %User{role: "teacher"}}} = socket) do
    assignment = AssignmentList.get_assignment!(id)
    {:ok, _} = AssignmentList.delete_assignment(assignment)

    {:noreply, stream_delete(socket, :assignments, assignment)}
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "unauthorized")
     |> push_patch(to: ~p"/assignments")}
  end


  attr :user, User, required: true
  attr :assignments, :list, required: true

  def assignments_table(%{user: %User{role: "teacher"}} = assigns) do
    ~H"""
      <.table
        id="assignments"
        rows={@assignments}
        row_click={fn {_id, assignment} -> JS.navigate(~p"/assignments/#{assignment}") end}
      >
        <:col :let={{_id, assignment}} label="Assignment name">
          <%= assignment.assignment_name %>
        </:col>
        <:col :let={{_id, assignment}} label="Visible"><%= assignment.visible %></:col>
        <:col :let={{_id, assignment}} label="Deadline"><%= Time.get_pretty_datetime(assignment.deadline) %></:col>
        <:action :let={{_id, assignment}}>
          <div class="sr-only">
            <.link navigate={~p"/assignments/#{assignment}"}>Show</.link>
          </div>
          <.link patch={~p"/assignments/#{assignment}/edit"} replace={true}>Edit</.link>
        </:action>
        <:action :let={{id, assignment}}>
          <.link
            phx-click={JS.push("delete", value: %{id: assignment.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    """
  end

  def assignments_table(%{user: %User{role: "ta"}} = assigns) do
    ~H"""
      <.table
        id="assignments"
        rows={@assignments}
        row_click={fn {_id, assignment} -> JS.navigate(~p"/assignments/#{assignment}") end}
      >
        <:col :let={{_id, assignment}} label="Assignment name">
          <%= assignment.assignment_name %>
        </:col>
        <:col :let={{_id, assignment}} label="Visible"><%= assignment.visible %></:col>
        <:col :let={{_id, assignment}} label="Deadline"><%= Time.get_pretty_datetime(assignment.deadline) %></:col>
        <:action :let={{_id, assignment}}>
          <div class="sr-only">
            <.link navigate={~p"/assignments/#{assignment}"}>Show</.link>
          </div>
        </:action>
      </.table>
    """
  end

  def assignments_table(%{user: %User{role: "student"}} = assigns) do
    ~H"""
      <.table
        id="assignments"
        rows={@assignments}
        row_click={fn {_id, assignment} -> JS.navigate(~p"/assignments/#{assignment}") end}
      >
        <:col :let={{_id, assignment}} label="Assignment name">
          <%= assignment.assignment_name %>
        </:col>
        <:col :let={{_id, assignment}} label="Deadline"><%= Time.get_pretty_datetime(assignment.deadline) %></:col>
      </.table>
    """
  end
end
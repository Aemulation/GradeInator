defmodule GradeInatorWeb.GroupLive.Index do
  use GradeInatorWeb, :live_view

  alias GradeInator.Repo
  alias GradeInator.Course.Group
  alias GradeInator.AssignmentList

  @impl true
  def mount(%{"assignment_id" => assignment_id} = _params, _session, socket) do
    assignment = AssignmentList.get_assignment!(assignment_id)
    groups = Repo.all(Group)

    {:ok,
     socket
     |> assign(:assignment, assignment)
     |> stream(:groups, groups)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Groups")
  end

  defp apply_action(socket, :show, %{"group_id" => group_id} = _params) do
    group = Repo.get!(Group, group_id)

    socket
    |> assign(:group, group)
    |> assign(:page_title, group.name)
  end
end

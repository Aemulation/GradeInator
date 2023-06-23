defmodule GradeInatorWeb.AssignmentLiveTest do
  use GradeInatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import GradeInator.AssignmentListFixtures

  @create_attrs %{assignment_description: "some assignment_description", assignment_name: "some assignment_name", deadline: "2023-04-15T10:49:00", visible: true}
  @update_attrs %{assignment_description: "some updated assignment_description", assignment_name: "some updated assignment_name", deadline: "2023-04-16T10:49:00", visible: false}
  @invalid_attrs %{assignment_description: nil, assignment_name: nil, deadline: nil, visible: false}

  defp create_assignment(_) do
    assignment = assignment_fixture()
    %{assignment: assignment}
  end

  describe "Index" do
    setup [:create_assignment]

    test "lists all assignments", %{conn: conn, assignment: assignment} do
      {:ok, _index_live, html} = live(conn, ~p"/assignments")

      assert html =~ "Listing Assignments"
      assert html =~ assignment.assignment_description
    end

    test "saves new assignment", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/assignments")

      assert index_live |> element("a", "New Assignment") |> render_click() =~
               "New Assignment"

      assert_patch(index_live, ~p"/assignments/new")

      assert index_live
             |> form("#assignment-form", assignment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#assignment-form", assignment: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/assignments")

      html = render(index_live)
      assert html =~ "Assignment created successfully"
      assert html =~ "some assignment_description"
    end

    test "updates assignment in listing", %{conn: conn, assignment: assignment} do
      {:ok, index_live, _html} = live(conn, ~p"/assignments")

      assert index_live |> element("#assignments-#{assignment.id} a", "Edit") |> render_click() =~
               "Edit Assignment"

      assert_patch(index_live, ~p"/assignments/#{assignment}/edit")

      assert index_live
             |> form("#assignment-form", assignment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#assignment-form", assignment: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/assignments")

      html = render(index_live)
      assert html =~ "Assignment updated successfully"
      assert html =~ "some updated assignment_description"
    end

    test "deletes assignment in listing", %{conn: conn, assignment: assignment} do
      {:ok, index_live, _html} = live(conn, ~p"/assignments")

      assert index_live |> element("#assignments-#{assignment.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#assignments-#{assignment.id}")
    end
  end

  describe "Show" do
    setup [:create_assignment]

    test "displays assignment", %{conn: conn, assignment: assignment} do
      {:ok, _show_live, html} = live(conn, ~p"/assignments/#{assignment}")

      assert html =~ "Show Assignment"
      assert html =~ assignment.assignment_description
    end

    test "updates assignment within modal", %{conn: conn, assignment: assignment} do
      {:ok, show_live, _html} = live(conn, ~p"/assignments/#{assignment}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Assignment"

      assert_patch(show_live, ~p"/assignments/#{assignment}/show/edit")

      assert show_live
             |> form("#assignment-form", assignment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#assignment-form", assignment: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/assignments/#{assignment}")

      html = render(show_live)
      assert html =~ "Assignment updated successfully"
      assert html =~ "some updated assignment_description"
    end
  end
end

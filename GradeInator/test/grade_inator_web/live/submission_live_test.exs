defmodule GradeInatorWeb.SubmissionLiveTest do
  use GradeInatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import GradeInator.SubmissionListFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_submission(_) do
    submission = submission_fixture()
    %{submission: submission}
  end

  describe "Index" do
    setup [:create_submission]

    test "lists all submissions", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/submissions")

      assert html =~ "Listing Submissions"
    end

    test "saves new submission", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/submissions")

      assert index_live |> element("a", "New Submission") |> render_click() =~
               "New Submission"

      assert_patch(index_live, ~p"/submissions/new")

      assert index_live
             |> form("#submission-form", submission: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#submission-form", submission: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/submissions")

      html = render(index_live)
      assert html =~ "Submission created successfully"
    end

    test "updates submission in listing", %{conn: conn, submission: submission} do
      {:ok, index_live, _html} = live(conn, ~p"/submissions")

      assert index_live |> element("#submissions-#{submission.id} a", "Edit") |> render_click() =~
               "Edit Submission"

      assert_patch(index_live, ~p"/submissions/#{submission}/edit")

      assert index_live
             |> form("#submission-form", submission: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#submission-form", submission: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/submissions")

      html = render(index_live)
      assert html =~ "Submission updated successfully"
    end

    test "deletes submission in listing", %{conn: conn, submission: submission} do
      {:ok, index_live, _html} = live(conn, ~p"/submissions")

      assert index_live |> element("#submissions-#{submission.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#submissions-#{submission.id}")
    end
  end

  describe "Show" do
    setup [:create_submission]

    test "displays submission", %{conn: conn, submission: submission} do
      {:ok, _show_live, html} = live(conn, ~p"/submissions/#{submission}")

      assert html =~ "Show Submission"
    end

    test "updates submission within modal", %{conn: conn, submission: submission} do
      {:ok, show_live, _html} = live(conn, ~p"/submissions/#{submission}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Submission"

      assert_patch(show_live, ~p"/submissions/#{submission}/show/edit")

      assert show_live
             |> form("#submission-form", submission: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#submission-form", submission: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/submissions/#{submission}")

      html = render(show_live)
      assert html =~ "Submission updated successfully"
    end
  end
end

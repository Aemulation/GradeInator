defmodule GradeInator.AssignmentListFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GradeInator.AssignmentList` context.
  """

  @doc """
  Generate a assignment.
  """
  def assignment_fixture(attrs \\ %{}) do
    {:ok, assignment} =
      attrs
      |> Enum.into(%{
        assignment_description: "some assignment_description",
        assignment_name: "some assignment_name",
        deadline: ~N[2023-04-15 10:49:00],
        visible: true
      })
      |> GradeInator.AssignmentList.create_assignment()

    assignment
  end
end

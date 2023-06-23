defmodule GradeInator.SubmissionListFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GradeInator.SubmissionList` context.
  """

  @doc """
  Generate a submission.
  """
  def submission_fixture(attrs \\ %{}) do
    {:ok, submission} =
      attrs
      |> Enum.into(%{
        assignment_id: 42,
        state: :ungraded
      })
      |> GradeInator.SubmissionList.create_submission()

    submission
  end

  @doc """
  Generate a submission.
  """
  def submission_fixture(attrs \\ %{}) do
    {:ok, submission} =
      attrs
      |> Enum.into(%{

      })
      |> GradeInator.SubmissionList.create_submission()

    submission
  end
end

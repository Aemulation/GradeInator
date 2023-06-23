defmodule GradeInator.SubmissionList do
  @moduledoc """
  The SubmissionList context.
  """

  import Ecto.Query
  alias Ecto.Repo
  alias GradeInator.Course.SubmissionState
  alias GradeInator.Course.SubmissionScore
  alias GradeInator.Repo

  alias GradeInator.Course.Submission
  alias GradeInator.AssignmentList.Assignment
  alias GradeInator.Course.User

  @doc """
  Returns the list of submissions.

  ## Examples

      iex> list_submissions()
      [%Submission{}, ...]

  """
  def list_submissions do
    Repo.all(Submission)
    |> Repo.preload([:state])
  end

  def list_submissions(%Assignment{id: assignment_id}, %User{id: user_id}) do
    Repo.all(
      from(s in Submission,
        where: s.assignment_id == ^assignment_id and s.user_id == ^user_id,
        order_by: [desc: s.inserted_at]
      )
    )
    |> Repo.preload([:state])
  end

  @doc """
  Gets a single submission.

  Raises `Ecto.NoResultsError` if the Submission does not exist.

  ## Examples

      iex> get_submission!(123)
      %Submission{}

      iex> get_submission!(456)
      ** (Ecto.NoResultsError)

  """
  def get_submission!(id) do
    Repo.get!(Submission, id)
  end

  defp preload_list_public(submission_id) do
    submission_score_query = from sc in SubmissionScore,
      left_join: as in assoc(sc, :assignment_score),
      where: as.visible_to_public == true and ^submission_id == sc.submission_id,
      preload: [:assignment_score]

    [:state, submission_scores: submission_score_query]
  end

  defp preload_list_private() do
   [:state, submission_scores: [:assignment_score]]
  end

  def get_submission_public!(submission_id) do
    submission_query = from s in Submission, preload: ^preload_list_public(submission_id)

    Repo.get!(submission_query, submission_id)
  end

  def preload_submission_public(%Submission{id: submission_id} = submission) do
    Repo.preload(submission, preload_list_public(submission_id))
  end

  def preload_submission_private(%Submission{} = submission) do
    Repo.preload(submission, preload_list_private())
  end

  @doc """
  Creates a submission.

  ## Examples

      iex> create_submission(%{field: value})
      {:ok, %Submission{}}

      iex> create_submission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_submission(submission, attrs \\ %{}) do
    ungraded_state = GradeInator.Repo.get_by!(SubmissionState, state: "ungraded")

    submission
    |> Submission.changeset(Map.put(attrs, :state, ungraded_state))
    |> Repo.insert()
  end

  @doc """
  Updates a submission.

  ## Examples

      iex> update_submission(submission, %{field: new_value})
      {:ok, %Submission{}}

      iex> update_submission(submission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_submission(%Submission{} = submission, attrs) do
    submission
    |> Submission.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a submission.

  ## Examples

      iex> delete_submission(submission)
      {:ok, %Submission{}}

      iex> delete_submission(submission)
      {:error, %Ecto.Changeset{}}

  """
  def delete_submission(%Submission{} = submission) do
    Repo.delete(submission)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking submission changes.

  ## Examples

      iex> change_submission(submission)
      %Ecto.Changeset{data: %Submission{}}

  """
  def change_submission(%Submission{} = submission, attrs \\ %{}) do
    Submission.changeset(submission, attrs)
  end

  # def get_latest_submission_for_each_group(%Assignment{}) do
  #   subquery_group_ids =
  #     from s in Submission,
  #       where: not is_nil(s.group_id),
  #       group_by: [s.group_id, s.inserted_at],
  #       order_by: s.inserted_at,
  #       select: s.group_id
  #
  #   query_distinct_group_ids =
  #     from subquery(subquery_group_ids),
  #       distinct: true
  #
  #   Repo.all(from g in Group, where: g.id in subquery(query_distinct_group_ids))
  # end

  # def get_groups_with_submission do
  #   query =
  #     from(
  #       from s in Submission,
  #         where: not is_nil(s.group_id),
  #         select: s.group_id,
  #         distinct: true
  #     )
  #
  #   group_ids = Repo.all(query)
  #   IO.inspect(group_ids)
  # end
end

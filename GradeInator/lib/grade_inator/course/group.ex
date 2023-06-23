defmodule GradeInator.Course.Group do
  alias GradeInator.Course.Group

  alias GradeInator.Course.Submission

  use Ecto.Schema
  import Ecto.Changeset

  alias GradeInator.Repo
  import Ecto.Query

  @derive [Poison.Decoder]
  @primary_key {:id, :id, autogenerate: false}
  schema "groups" do
    field :name, :string

    has_many(:submissions, Submission, preload_order: [desc: :inserted_at])

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:id, :name])
    |> validate_required([:id, :name])
    |> unique_constraint([:name])
  end

  def fetch_using_canvas(access_token) do
    course_id = Confex.fetch_env!(:grade_inator, :canvas_course_id)

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(
             "#{Confex.fetch_env!(:grade_inator, :canvas_address)}/api/v1/users/self/groups",
             [{"Authorization", "Bearer #{access_token}"}]
           ),
         {:ok, groups} <- Poison.decode(body) do
      get_correct_group(access_token, groups, course_id)
    end
  end

  defp fetch_group_from_id(access_token, group_id) do
    handle_group_query(
      HTTPoison.get!(
        "#{Confex.fetch_env!(:grade_inator, :canvas_address)}/api/v1/groups/#{group_id}?include=users",
        [
          {"Authorization", "Bearer #{access_token}"}
        ]
      )
    )
  end

  defp handle_group_query(%HTTPoison.Response{status_code: 200, body: body}) do
    Poison.decode(body, as: %Group{})
  end

  defp handle_group_query(%HTTPoison.Response{status_code: 401}) do
    {:error, :unauthorized}
  end

  defp handle_group_query(%HTTPoison.Response{}) do
    {:error, :unexpected}
  end

  defp get_correct_group(
         access_token,
         [
           %{
             "context_type" => "Course",
             "id" => group_id,
             "course_id" => group_course_id,
             "name" => "SubmissionGroup" <> _group_number
           }
           | groups
         ],
         course_id
       ) do
    case group_course_id do
      ^course_id ->
        case Repo.get(Group, group_id) do
          nil ->
            fetch_group_from_id(access_token, group_id)

          group ->
            {:ok, group}
        end

      _ ->
        get_correct_group(access_token, groups, course_id)
    end
  end

  defp get_correct_group(access_token, [_ | groups], course_id) do
    get_correct_group(access_token, groups, course_id)
  end

  defp get_correct_group(_access_token, [], _course_id) do
    {:ok, nil}
  end

  def get_submissions(%Group{id: id}) do
    query =
      from(s in Submission,
        where: s.group_id == ^id
      )

    Repo.all(query)
  end

  def get_latest_submission_per_group() do
    query =
      from(s in Submission,
        where: s.group_id == 1,
        order_by: [desc: s.inserted_at],
        select: [s.id]
      )

    Repo.all(query)
  end
end

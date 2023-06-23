defmodule GradeInator.Course.User do
  alias GradeInator.Course.User
  alias GradeInator.Course.Group
  alias GradeInator.Repo

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: false}
  schema "users" do
    field :access_token, :string, virtual: true
    field :role, :string
    field :name, :string

    belongs_to :group, Group, on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, params) do
    user
    |> cast(params, [:id, :role, :name])
    |> cast_assoc(:group)
    |> validate_required([:id, :role, :name])
    |> unique_constraint([:name])
  end

  defp fetch_user_data(%User{access_token: access_token}) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(
             "#{Confex.fetch_env!(:grade_inator, :canvas_address)}/api/v1/users/self",
             [
               {"Authorization", "Bearer #{access_token}"}
             ]
           ) do
      Poison.decode(body)
    end
  end

  defp fetch_course_data(%User{access_token: access_token}, course_id) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(
             "#{Confex.fetch_env!(:grade_inator, :canvas_address)}/api/v1/users/self/courses",
             [
               {"Authorization", "Bearer #{access_token}"}
             ]
           ),
         {:ok, [%{"id" => ^course_id, "enrollments" => [%{"type" => role}]} | _]} <-
           Poison.decode(body) do
      {:ok, %{"role" => role}}
    end
  end

  # def fetch_latest_group(%User{access_token: access_token}) do
  #   course_id = Confex.fetch_env!(:grade_inator, :canvas_course_id)
  #
  #   case Group.fetch_using_canvas(access_token) do
  #     {:ok, group} -> %User{user | group_id: group.id, group: group}
  #     {:error, :not_in_group} -> %User{user | group_id: nil, group: nil}
  #   end
  # end

  def fetch_using_canvas(access_token) do
    user = %User{access_token: access_token}

    with {:ok, %{"id" => id, "name" => name}} = fetch_user_data(user),
         {:ok, %{"role" => role}} =
           fetch_course_data(user, Confex.fetch_env!(:grade_inator, :canvas_course_id)) do
      user = %User{
        user |
        name: name,
        role: role,
        id: id
      }

      user =
        case Group.fetch_using_canvas(access_token) do
          {:ok, nil} -> %User{user | group_id: nil, group: nil}
          {:ok, group} -> %User{user | group_id: group.id, group: group}
        end

      Repo.insert(user, on_conflict: :replace_all)
    end
  end
end

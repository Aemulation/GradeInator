defmodule GradeInatorWeb.AuthController do
  use GradeInatorWeb, :controller

  alias GradeInator.Course.User

  def request(conn, _params) do
    redirect(conn,
      external:
        "#{Confex.fetch_env!(:grade_inator, :canvas_address)}/login/oauth2/auth?" <>
          "client_id=#{Confex.fetch_env!(:grade_inator, :canvas_client_id)}&" <>
          "response_type=code&" <>
          "redirect_uri=http://localhost:4000/auth/canvas/callback"
    )
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been logged out!")
    |> redirect(to: ~p"/")
  end

  def callback(conn, %{"code" => code} = _params) do
    result =
      HTTPoison.post(
        "#{Confex.fetch_env!(:grade_inator, :canvas_address)}/login/oauth2/token",
        "{\"code\": \"#{code}\", " <>
          "\"grant_type\":\"authorization_code\", " <>
          "\"client_id\":\"#{Confex.fetch_env!(:grade_inator, :canvas_client_id)}\", " <>
          "\"client_secret\":\"#{Confex.fetch_env!(:grade_inator, :canvas_client_secret)}\", " <>
          "\"redirect_uri\":\"http://localhost:4000/auth/canvas/callback\"}",
        [{"Content-Type", "application/json"}]
      )

    case result do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, %{"access_token" => access_token}} ->
            {:ok, user} = User.fetch_using_canvas(access_token)

            conn
            |> put_session(:user, user)
            |> put_flash(:info, "logged in as #{user.name}")
            |> redirect(to: ~p"/assignments")

          _ ->
            conn
            |> put_flash(:error, "Did not receive an access token")
            |> redirect(to: ~p"/")
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        conn
        |> put_flash(:error, "did not get access_token: #{status_code}")
        |> redirect(to: ~p"/")

        # TODO: handle an error from the canvas api.
        # Maybe this can happen if we use the wrong POST data in the request.
    end
  end
end

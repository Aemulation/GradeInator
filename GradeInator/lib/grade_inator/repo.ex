defmodule GradeInator.Repo do
  use Ecto.Repo,
    otp_app: :grade_inator,
    adapter: Ecto.Adapters.MyXQL
end

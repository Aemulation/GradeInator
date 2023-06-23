defmodule GradeInatorWeb.Router do
  use GradeInatorWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {GradeInatorWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/auth", GradeInatorWeb do
    pipe_through :browser

    get "/logout", AuthController, :logout

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/", GradeInatorWeb do
    pipe_through(:browser)

    get("/", PageController, :home)

    live("/assignments", AssignmentLive.Index, :index)
    live("/assignments/new", AssignmentLive.Index, :new)
    live("/assignments/:id/edit", AssignmentLive.Index, :edit)

    live("/assignments/:id", AssignmentLive.Show, :show)
    live("/assignments/:id/show/edit", AssignmentLive.Show, :edit)
    live("/assignments/:assignment_id/groups", GroupLive.Index, :index)
    live("/assignments/:assignment_id/groups/:group_id", GroupLive.Show, :show)
    live("/assignments/:assignment_id/groups/:group_id/new", GroupLive.Show, :new)

    live "/assignments/:assignment_id/submissions", SubmissionLive.Index, :index
    live "/assignments/:assignment_id/submissions/new", SubmissionLive.Index, :new

    live "/assignments/:assignment_id/submissions/:submission_id", SubmissionLive.Show, :show

    get "/assignments/:assignment_id/submissions/:submission_id/download",
        DownloadSubmissionController,
        :download_submission
  end

  # Other scopes may use custom stacks.
  # scope "/api", GradeInatorWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:grade_inator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: GradeInatorWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end

defmodule GradeInatorWeb.SubmissionLive.FormComponent do
  use GradeInatorWeb, :live_component

  alias GradeInator.SubmissionList
  alias GradeInator.Course.Group

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage submission records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="submission-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= for entry <- @uploads.avatar.entries do %>
          <h1>
            <%= entry.client_name %>
            <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
            <a href="#" phx-click="cancel-entry" phx-value-ref={entry.ref} phx-target={@myself}>
              Cancel
            </a>
          </h1>
        <% end %>
        <.live_file_input upload={@uploads.avatar} />

        <%= for {_ref, msg} <- @uploads.avatar.errors do %>
          <p class="alert alert-danger">entry.client_name: <%= Phoenix.Naming.humanize(msg) %></p>
        <% end %>
        <%= for missing_file <- @missing_files do %>
          <.error>Missing required file: <%= missing_file.file_name %></.error>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Submission</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{submission: submission, user: user} = assigns, socket) do
    changeset = SubmissionList.change_submission(submission, %{group: user.group})

    assigns = Map.put(assigns, :missing_files, submission.assignment.required_submission_files)

    {:ok,
     socket
     |> assign(assigns)
     |> allow_upload(:avatar, accept: :any, max_entries: 4)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", _, socket) do
    {:noreply, validate_required_files(socket)}
  end

  def handle_event("save", %{}, socket) do
    case socket.assigns.missing_files do
      [] ->
        save_submission(socket, socket.assigns.action, %{})

      [_ | _] ->
        {:noreply, socket}
    end
  end

  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply,
     socket
     |> cancel_upload(:avatar, ref)
     |> validate_required_files()}
  end

  def validate_required_files(socket) do
    file_is_submitted = fn file_name ->
      Enum.any?(socket.assigns.uploads.avatar.entries, fn entry ->
        entry.client_name == file_name
      end)
    end

    missing_files =
      Enum.filter(
        socket.assigns.submission.assignment.required_submission_files,
        fn required_submission_file ->
          !file_is_submitted.(required_submission_file.file_name)
        end
      )

    assign(socket, :missing_files, missing_files)
  end

  defp save_submission(socket, :new, submission_params) do
    {:ok, group} = Group.fetch_using_canvas(socket.assigns.user.access_token)
    submission_params = Map.put(submission_params, :group, group)

    case SubmissionList.create_submission(socket.assigns.submission, submission_params) do
      {:ok, submission} ->
        case uploaded_entries(socket, :avatar) do
          {[_ | _] = entries, []} ->
            dest_dir =
              Path.join(
                :code.priv_dir(:grade_inator),
                "static/submissions/#{submission.id}/submission_files"
              )

            File.mkdir_p(dest_dir)

            uploaded_files =
              for entry <- entries do
                consume_uploaded_entry(socket, entry, fn %{path: path} ->
                  dest_file = Path.join(dest_dir, entry.client_name)
                  File.cp!(path, dest_file)
                  {:ok, String.to_charlist(Path.basename(dest_file))}
                end)
              end

            :zip.create(~c"#{dest_dir}/../submission_files.zip", uploaded_files,
              cwd: String.to_charlist(dest_dir)
            )

            notify_parent({:saved, submission})

            {:noreply,
             socket
             |> put_flash(:info, "Submission created successfully")
             |> push_patch(to: socket.assigns.patch, replace: true )}

          _ ->
            SubmissionList.delete_submission(submission)
            {:noreply, put_flash(socket, :error, "submission upload failed")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

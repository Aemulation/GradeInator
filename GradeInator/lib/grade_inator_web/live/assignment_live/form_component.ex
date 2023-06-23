defmodule GradeInatorWeb.AssignmentLive.FormComponent do
  use GradeInatorWeb, :live_component

  alias GradeInator.AssignmentList
  alias GradeInator.AssignmentList.AssignmentScoreType
  alias GradeInator.Course.User
  alias GradeInator.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="assignment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:assignment_name]} type="text" label="Assignment name" />
        <.input field={@form[:assignment_description]} type="textarea" label="Assignment description" />
        <.input field={@form[:visible]} type="checkbox" label="Visible" />
        <.input field={@form[:deadline]} type="datetime-local" label="Deadline" />
        <.label>Grade files</.label>
        <%= for entry <- @uploads.grade_file_names.entries do %>
          <h1>
            <%= entry.client_name %>
            <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
            <a href="#" phx-click="cancel-entry" phx-value-ref={entry.ref} phx-target={@myself}>
              Cancel
            </a>
          </h1>
        <% end %>
        <.live_file_input upload={@uploads.grade_file_names} />
        <%= if !@assignment.id && !Enum.member?(Enum.map(@uploads.grade_file_names.entries, fn entry -> entry.client_name end), "grade.sh") do %>
          <.error>Missing grade.sh</.error>
        <% end %>

        <.label>Required Submission Files</.label>
        <.inputs_for :let={required_submission_file} field={@form[:required_submission_files]}>
          <input
            type="hidden"
            name="assignment[required_submission_files_sort][]"
            value={required_submission_file.index}
          />
          <div class="flex mt-0">
            <div class="flex-auto mr-5">
              <.input field={required_submission_file[:file_name]} type="text" />
            </div>
            <label>
              <input
                type="checkbox"
                name="assignment[required_submission_files_drop][]"
                value={required_submission_file.index}
                class="hidden"
              />
              <.icon name="hero-x-mark" class="w-6 h-6 relative top-3" />
            </label>
          </div>
        </.inputs_for>
        <label class="block cursor-pointer">
          <input type="checkbox" name="assignment[required_submission_files_sort][]" class="hidden" />
          Add more submission files
        </label>
        <.label>Score fields</.label>
        <.inputs_for :let={assignment_score} field={@form[:assignment_scores]}>
          <input
            type="hidden"
            name="assignment[assignment_scores_sort][]"
            value={assignment_score.index}
          />
          <div class="flex mt-0">
            <div class="flex-auto mr-3">
              <.input field={assignment_score[:key]} type="text" />
            </div>
            <div class="flex-none relative top-5 px-1">
              <.input field={assignment_score[:visible_to_public]} type="checkbox" />
            </div>
            <div class="flex-none relative top-1 px-1">
              <.input
                field={assignment_score[:assignment_score_type_id]}
                type="select"
                options={
                  Enum.map(Repo.all(AssignmentScoreType), fn assignment_score_type ->
                    {assignment_score_type.type, assignment_score_type.id}
                  end)
                }
              />
            </div>

            <label>
              <input
                type="checkbox"
                name="assignment[assignment_scores_drop][]"
                value={assignment_score.index}
                class="hidden"
              />
              <.icon name="hero-x-mark" class="w-6 h-6 relative top-3" />
            </label>
          </div>
        </.inputs_for>

        <label class="block cursor-pointer">
          <input type="checkbox" name="assignment[assignment_scores_sort][]" class="hidden" />
          Add more score fields
        </label>
        <:actions>
          <.button type="submit" phx-disable-with="Saving...">Save Assignment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{assignment: assignment} = assigns, socket) do
    changeset = AssignmentList.change_assignment(assignment)

    {:ok,
     socket
     |> assign(assigns)
     |> allow_upload(:grade_file_names, accept: :any, max_entries: 4)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"assignment" => assignment_params},
        %{assigns: %{user: %User{role: "teacher"}}} = socket
      ) do
    changeset =
      socket.assigns.form.data
      |> AssignmentList.change_assignment(assignment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("validate", assigns, socket) do
    {:noreply,
     socket
     |> assign(assigns)
     |> put_flash(:error, "unauthorized")
     |> push_patch(to: socket.assigns.patch, replace: true)}
  end

  @impl true
  def handle_event("add_required_submission_file", _, socket) do
    form = socket.assigns.form

    new_required_submission_file =
      Ecto.build_assoc(socket.assigns.assignment, :required_submission_files, %{
        file_name: ""
      })

    changes =
      case form.source.changes do
        %{required_submission_files: [_ | _]} ->
          Map.put(
            form.source.changes,
            :required_submission_files,
            form.source.changes.required_submission_files ++ [new_required_submission_file]
          )

        _ ->
          Map.put(
            form.source.changes,
            :required_submission_files,
            form.data.required_submission_files ++ [new_required_submission_file]
          )
      end

    source = Map.put(form.source, :changes, changes)

    {:noreply, assign(socket, :form, %{form | source: source})}
  end

  def handle_event("remove_required_submission_file", %{"index" => index}, socket) do
    form = socket.assigns.form
    index = String.to_integer(index)

    changes =
      case form.source.changes do
        %{required_submission_files: [_ | _]} ->
          Map.put(
            form.source.changes,
            :required_submission_files,
            List.delete_at(form.source.changes.required_submission_files, index)
          )

        _ ->
          Map.put(
            form.source.changes,
            :required_submission_files,
            List.delete_at(form.data.required_submission_files, index)
          )
      end

    source = Map.put(form.source, :changes, changes)

    {:noreply, assign(socket, :form, %{form | source: source})}
  end

  def handle_event(
        "save",
        %{"assignment" => assignment_params},
        %{assigns: %{user: %User{role: "teacher"}}} = socket
      ) do
    case socket.assigns.action do
      :new ->
        case socket.assigns.uploads.grade_file_names.entries do
          [] -> {:noreply, socket}
          _ -> save_assignment(socket, socket.assigns.action, assignment_params)
        end

      :edit ->
        save_assignment(socket, socket.assigns.action, assignment_params)
    end
  end

  def handle_event("save", params, socket) do
    {:noreply,
     socket
     |> assign(params)
     |> put_flash(:error, "unauthorized")
     |> push_patch(to: socket.assigns.patch)}
  end

  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :grade_file_names, ref)}
  end

  defp save_assignment(socket, :edit, assignment_params) do
    case AssignmentList.update_assignment(socket.assigns.assignment, assignment_params) do
      {:ok, assignment} ->
        case uploaded_entries(socket, :grade_file_names) do
          {[_ | _] = entries, []} ->
            dest_dir =
              Path.join(
                :code.priv_dir(:grade_inator),
                "static/assignments/#{assignment.id}/grade_files"
              )

            File.mkdir_p(dest_dir)

            uploaded_files =
              for entry <- entries do
                consume_uploaded_entry(socket, entry, fn %{path: path} ->
                  dest_file = Path.join(dest_dir, entry.client_name)
                  File.cp!(path, dest_file)
                  File.chmod(dest_file, 0o700)
                  {:ok, String.to_charlist(Path.basename(dest_file))}
                end)
              end

            :zip.create(~c"#{dest_dir}/../grade_files.zip", uploaded_files,
              cwd: String.to_charlist(dest_dir)
            )

          {[], []} ->
            nil
        end

        notify_parent({:saved, assignment})

        {:noreply,
         socket
         |> clear_flash()
         |> put_flash(:info, "Assignment updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Assignment update failed")
         |> assign_form(changeset)}
    end
  end

  defp save_assignment(socket, :new, assignment_params) do
    case AssignmentList.create_assignment(assignment_params) do
      {:ok, assignment} ->
        case uploaded_entries(socket, :grade_file_names) do
          {[_ | _] = entries, []} ->
            dest_dir =
              Path.join(
                :code.priv_dir(:grade_inator),
                "static/assignments/#{assignment.id}/grade_files"
              )

            File.mkdir_p(dest_dir)

            uploaded_files =
              for entry <- entries do
                consume_uploaded_entry(socket, entry, fn %{path: path} ->
                  dest_file = Path.join(dest_dir, entry.client_name)
                  File.cp!(path, dest_file)
                  File.chmod(dest_file, 0o700)
                  {:ok, String.to_charlist(Path.basename(dest_file))}
                end)
              end

            :zip.create(~c"#{dest_dir}/../grade_files.zip", uploaded_files,
              cwd: String.to_charlist(dest_dir)
            )

            notify_parent({:saved, assignment})

            {:noreply,
             socket
             |> put_flash(:info, "Assignment created successfully")
             |> push_patch(to: socket.assigns.patch)}

          _ ->
            AssignmentList.delete_assignment(assignment)
            {:noreply, put_flash(socket, :error, "assignment creation failed")}
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

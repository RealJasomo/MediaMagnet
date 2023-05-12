defmodule MediaMagnetWeb.FileLive.FormComponent do
  use MediaMagnetWeb, :live_component

  alias Mix.Tasks.Phx.Routes
  alias MediaMagnet.Files

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage file records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="file-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          prompt="Choose a value"
          options={Ecto.Enum.values(MediaMagnet.Files.File, :type)}
        />
        <.live_file_input upload={@uploads.data_file} />
        <:actions>
          <.button phx-disable-with="Saving...">Save File</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{file: file} = assigns, socket) do
    changeset = Files.change_file(file)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:uploaded_files, [])
     |> allow_upload(:data_file, accept: :any, max_entries: 1, max_file_size: 1_000_000_000_000)}
  end

  @impl true
  def handle_event("validate", %{"file" => file_params}, socket) do
    changeset =
      socket.assigns.file
      |> Files.change_file(file_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  @impl true
  def handle_event("save", %{"file" => file_params}, socket) do
    file_paths =
      consume_uploaded_entries(socket, :data_file, fn %{path: path}, entry ->
        dest =
          Path.join([
            System.cwd!(),
            "data",
            "uploads",
            "#{entry.uuid}.#{ext(entry)}"
          ])

        File.cp!(path, dest)
        {:ok, static_path(socket, "/uploads/#{entry.uuid}.#{ext(entry)}")}
      end)

    file_path = List.first(file_paths)
    new_params = Map.put(file_params, "path", file_path)
    save_file(socket, socket.assigns.action, new_params)
  end

  defp save_file(socket, :edit, file_params) do
    case Files.update_file(socket.assigns.file, file_params) do
      {:ok, file} ->
        notify_parent({:saved, file})

        {:noreply,
         socket
         |> put_flash(:info, "File updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_file(socket, :new, file_params) do
    case Files.create_file(file_params) do
      {:ok, file} ->
        notify_parent({:saved, file})

        {:noreply,
         socket
         |> put_flash(:info, "File created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

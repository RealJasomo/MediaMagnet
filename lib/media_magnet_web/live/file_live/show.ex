defmodule MediaMagnetWeb.FileLive.Show do
  use MediaMagnetWeb, :live_view

  alias MediaMagnet.Files

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:file, Files.get_file!(id))
     |> assign(:current_path, URI.parse(url).path)}
  end

  defp page_title(:show), do: "Show File"
  defp page_title(:edit), do: "Edit File"
end

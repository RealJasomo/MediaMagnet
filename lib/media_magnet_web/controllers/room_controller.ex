defmodule MediaMagnetWeb.RoomController do
  use MediaMagnetWeb, :controller

  def index(conn, %{"room_id" => id, "display_name" => _name}) do
    current_path = conn.request_path
    render(conn, "index.html", room_id: id, current_path: current_path)
  end

  # display name is not present, redirect to home page with filled in room name
  def index(conn, %{"room_id" => id}) do
    redirect(conn, to: Routes.page_path(conn, :index, %{room_id: id}))
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, socket |> assign(:current_path, URI.parse(url).path)}
  end
end

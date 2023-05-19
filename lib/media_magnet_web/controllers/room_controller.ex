defmodule MediaMagnetWeb.RoomController do
  use MediaMagnetWeb, :controller
  alias MediaMagnet.Files

  def index(conn, %{"room_id" => id, "display_name" => _name}) do
    current_path = conn.request_path
    files = Files.list_files()
    render(conn, "index.html", room_id: id, current_path: current_path, files: files)
  end

  # display name is not present, redirect to home page with filled in room name
  def index(conn, %{"room_id" => id}) do
    current_path = conn.request_path
    files = Files.list_files()

    redirect(conn,
      to: Routes.page_path(conn, :index, %{room_id: id}),
      current_path: current_path,
      files: files
    )
  end
end

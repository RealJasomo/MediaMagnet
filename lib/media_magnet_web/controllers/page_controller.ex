defmodule MediaMagnetWeb.PageController do
  use MediaMagnetWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def index(conn, params) do
    current_path = conn.request_path
    render(conn, "index.html", room_id: Map.get(params, "room_id"), current_path: current_path)
  end

  def enter(conn, %{"room_name" => room_name, "display_name" => display_name}) do
    path =
      Routes.room_path(
        conn,
        :index,
        room_name,
        %{"display_name" => display_name}
      )

    redirect(conn, to: path)
  end

  def healthcheck(conn, _params) do
    conn
    |> send_resp(200, "")
  end
end

defmodule MediaMagnetWeb.MediaMagnet.FileStreamController do
  use MediaMagnetWeb, :controller

  def stream_file(conn, %{"id" => id}) do
    case MediaMagnet.Files.get_file!(id) do
      %MediaMagnet.Files.File{} = file ->
        video_path = Path.join([File.cwd!(), file.path])

        conn
        |> send_file(200, video_path, 0, :all)

      nil ->
        conn
        |> put_flash(:error, "File not found")
        |> redirect(to: "/files")
    end
  end
end

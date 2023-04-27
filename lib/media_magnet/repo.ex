defmodule MediaMagnet.Repo do
  use Ecto.Repo,
    otp_app: :media_magnet,
    adapter: Ecto.Adapters.Postgres
end

defmodule MediaMagnetWeb.UserSocket do
  use Phoenix.Socket

  channel("room:*", MediaMagnetWeb.PeerChannel)
  channel("together:*", MediaMagnetWeb.TogetherChannel)

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end

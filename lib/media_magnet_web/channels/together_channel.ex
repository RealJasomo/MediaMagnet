defmodule MediaMagnetWeb.TogetherChannel do
  use MediaMagnetWeb, :channel

  @impl true
  def join("together:" <> room_id, _payload, socket) do
    {:ok, socket |> assign(:room_id, room_id) |> assign(:current_video, nil)}
  end

  @impl true
  def handle_in("play", _payload, socket) do
    broadcast(socket, "play", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_in("pause", _payload, socket) do
    broadcast(socket, "pause", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_in("switch", %{"new_video" => new_video}, socket) do
    broadcast(socket, "switch", %{"new_video" => new_video})
    {:noreply, socket |> assign(:current_video, new_video)}
  end
end

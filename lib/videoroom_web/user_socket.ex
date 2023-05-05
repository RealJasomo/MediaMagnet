defmodule VideoRoomWeb.UserSocket do
  use Phoenix.Socket

  channel("room:*", VideoRoomWeb.PeerChannel)

 end

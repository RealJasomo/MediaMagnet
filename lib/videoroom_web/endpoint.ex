defmodule VideoRoomWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :videoroom_web

  socket("/socket", VideoRoomWeb.UserSocket,
   websocket: true,
   longpoll: false
  )
 end

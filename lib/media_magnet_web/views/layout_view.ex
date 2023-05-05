defmodule MediaMagnetWeb.LayoutView do
  use MediaMagnetWeb, :view

  def version() do
    Application.fetch_env!(:membrane_videoroom_demo, :version)
  end
end

defmodule MediaMagnetWeb.LayoutView do
  use MediaMagnetWeb, :view

  def version() do
    Application.fetch_env!(:media_magnet, :version)
  end
end

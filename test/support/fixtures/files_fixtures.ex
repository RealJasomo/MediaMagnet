defmodule MediaMagnet.FilesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MediaMagnet.Files` context.
  """

  @doc """
  Generate a file.
  """
  def file_fixture(attrs \\ %{}) do
    {:ok, file} =
      attrs
      |> Enum.into(%{
        name: "some name",
        path: "some path",
        type: :video
      })
      |> MediaMagnet.Files.create_file()

    file
  end
end

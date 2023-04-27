defmodule MediaMagnet.Files.File do
  use Ecto.Schema
  import Ecto.Changeset

  schema "files" do
    field :name, :string
    field :path, :string
    field :type, Ecto.Enum, values: [:video, :music, :document]

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:name, :path, :type])
    |> validate_required([:name, :path, :type])
  end
end

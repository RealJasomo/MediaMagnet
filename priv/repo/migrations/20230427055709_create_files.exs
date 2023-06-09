defmodule MediaMagnet.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :name, :string
      add :path, :string
      add :type, :string

      timestamps()
    end
  end
end

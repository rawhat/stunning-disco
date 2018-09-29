defmodule Codisco.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, []}

  schema "users" do
    field :username, :string
    field :password, :string
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :password])
    |> validate_required([:username, :password])
    |> unique_constraint(:username)
  end
end

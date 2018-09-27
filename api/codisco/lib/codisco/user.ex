defmodule Codisco.User do
  use Ecto.Schema

  @primary_key {:id, :integer, []}

  schema "users" do
    field :username, :string
    field :password, :string
  end
end

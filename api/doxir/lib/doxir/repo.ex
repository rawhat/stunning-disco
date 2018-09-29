defmodule Doxir.Repo do
  use Ecto.Repo,
    otp_app: :doxir,
    adapter: Ecto.Adapters.Postgres
end

defmodule Codisco.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      Codisco.Repo,
      {Plug.Adapters.Cowboy2, scheme: :http, plug: Codisco.Router, options: [port: 3000]}
    ]

    opts = [strategy: :one_for_one, name: Codisco.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

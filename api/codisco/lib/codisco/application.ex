defmodule Codisco.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      {Plug.Adapters.Cowboy2, scheme: :http, plug: Codisco.Router, options: [port: 3000, dispatch: dispatch]},
      Codisco.Repo,
      {Codisco.ScriptExecutor, []},
      #Plug.Adapters.Cowboy.child_spec(:http, Codisco.Router, [], [port: 3000, dispatch: dispatch]),
      {Codisco.SockHandler, []},
    ]

    #Plug.Adapters.Cowboy2.http(Codisco.Router, [], port: 3000)
    opts = [strategy: :one_for_one, name: Codisco.Supervisor]
    Supervisor.start_link(children, opts)
    Codisco.LogReader.start()
  end

  defp dispatch do
    [
      {:_, [
        {"/coder", Codisco.WsRouter, []},
        {:_, Plug.Adapters.Cowboy.Handler, {Codisco.Router, []}},
      ]}
    ]
  end
end

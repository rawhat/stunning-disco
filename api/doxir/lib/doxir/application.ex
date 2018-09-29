defmodule Doxir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Doxir.Repo,
      # Start the endpoint when the application starts
      DoxirWeb.Endpoint,
      # Starts a worker by calling: Doxir.Worker.start_link(arg)
      # {Doxir.Worker, arg},
      #{Doxir.ScriptExecutor, []},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Doxir.Supervisor]
    Supervisor.start_link(children, opts)
    #Codisco.LogReader.start()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DoxirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

defmodule Doxir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @base_url "http://10.0.2.15:2375"
  @containers_url "#{@base_url}/containers"

  def base_url, do: @base_url
  def containers_url, do: @containers_url

  def start(_type, _args) do
    children = [
      {Doxir.LogReader, []}
    ]

    opts = [strategy: :one_for_one, name: Doxir.Supervisor]
    Supervisor.start_link(children, opts)
    [{pid, _, _, _}] = Supervisor.which_children(Doxir.Supervisor)
    Doxir.ScriptRunner.start()
  end
end

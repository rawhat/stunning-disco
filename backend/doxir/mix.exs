defmodule Doxir.MixProject do
  use Mix.Project

  def project do
    [
      app: :doxir,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:amqp],
      extra_applications: [:logger],
      mod: {Doxir.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:amqp, "~> 1.0"},
      {:ranch_proxy_protocol, github: "heroku/ranch_proxy_protocol", override: true}
    ]
  end
end

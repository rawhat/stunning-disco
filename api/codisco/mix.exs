defmodule Codisco.MixProject do
  use Mix.Project

  def project do
    [
      app: :codisco,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :plug, :poison],
      mod: {Codisco.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cors_plug, "~> 1.5"},
      {:cowboy, "~> 2.4"},
      {:plug, "~> 1.5"},
      {:poison, "~> 3.1"},
      {:ecto, "~> 2.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end

defmodule Mona.MixProject do
  use Mix.Project

  def project do
    [
      app: :mona,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def escript do
    [
      main_module: Mona.Main
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :floki, :plug_cowboy, :poison, :httpoison],
      mod: {Mona.Main, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.26.0"},
      {:httpoison, "~> 1.8"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 5.0"}
    ]
  end
end

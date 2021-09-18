defmodule ExFactor.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_factor,
      name: "ExFactor",
      version: "0.2.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/ckochx/ex_factor"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  # defp elixirc_paths(_), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "test"]

  defp description do
    "ExFactor is a refactoring helper."
  end

  defp deps do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp package() do
    [
      name: "ExFactor",
      # These are the default files included in the package
      # files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
      #           license* CHANGELOG* changelog* src),
      licenses: ["CC-BY-NC-ND-4.0"],
      links: %{"GitHub" => "https://github.com/ckochx/ex_factor"}
    ]
  end
end

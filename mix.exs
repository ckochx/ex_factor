defmodule ExFactor.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_factor,
      name: "ExFactor",
      version: "0.2.1",
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
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "ExFactor is a refactoring helper that will find and replace instances of a module-function-arity in your source code."
  end

  defp deps do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp package() do
    [
      licenses: ["CC-BY-NC-ND-4.0"],
      links: %{"GitHub" => "https://github.com/ckochx/ex_factor"}
    ]
  end
end

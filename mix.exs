Code.compile_file("support/tracer.ex")

defmodule ExFactor.MixProject do
  use Mix.Project

  @name "ExFactor"
  @source_url "https://github.com/ckochx/ex_factor"
  @version "0.3.3"

  def project do
    [
      app: :ex_factor,
      name: @name,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      config_path: "./config/config.exs",
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      source_url: @source_url
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
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false, optional: true, app: false}
    ]
  end

  defp package() do
    [
      description: description(),
      licenses: ["CC-BY-NC-ND-4.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      logo: "assets/X.jpg",
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end

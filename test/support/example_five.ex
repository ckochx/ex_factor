defmodule ExFactor.Support.ExampleFive do
  @moduledoc """
  Support module for `ExFactor` testing.
  """

  alias ExFactor.Parser
  alias ExFactor.Callers
  import Parser

  def callers(mod), do: Callers.callers(mod)
  def all_funcs(input), do: all_functions(input)
  def more_funcs(path), do: Parser.public_functions(path)

  def another_func(path) do
    IO.puts "A functions"
  end

  defdelegate format(args, opts \\ []), to: ExFactor.Formatter

  def a_third_func(path) do
    path
    |> IO.puts()
    |> IO.inspect()
    |> IO.puts
  end
end

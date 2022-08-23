defmodule ExFactor.Support.ExampleSeven do
  @moduledoc """
  Support module for `ExFactor` testing.
  """

  alias ExFactor.Parser
  alias ExFactor.Callers
  import Parser

  def callers(mod), do: Callers.callers(mod)
  def all_funcs(input), do: all_functions(input)
end

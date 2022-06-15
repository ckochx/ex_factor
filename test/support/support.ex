defmodule ExFactor.Support do
  @moduledoc """
  Support module for `ExFactor` testing.
  """

  # use alias as: to verify the caller is found.
  alias ExFactor.Parser, as: P
  alias ExFactor.Callers

  def callers(mod), do: Callers.callers(mod)
  def all_functions(input), do: P.all_functions(input)
end

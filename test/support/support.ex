defmodule ExFactor.Support do
  @moduledoc """
  Support moduel for `ExFactor` testing.
  """

  alias ExFactor.Parser

  def callers(mod), do: ExFactor.callers(mod)
  def all_functions(input), do: Parser.all_functions(input)
end


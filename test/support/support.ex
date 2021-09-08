defmodule ExFactor.Support do
  @moduledoc """
  Support moduel for `ExFactor` testing.
  """

  # use alias as: to verify the caller is found.
  alias ExFactor.Parser, as: P

  def callers(mod), do: ExFactor.callers(mod)
  def all_functions(input), do: P.all_functions(input)
end

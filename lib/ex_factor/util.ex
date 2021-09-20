defmodule ExFactor.Util do
  @moduledoc false

  # TODO: we probably don't even need this function
  # use this as a dead code finder
  def module_to_string(module) when is_atom(module) do
    to_string(module)
  end

  def module_to_string(module), do: module
end

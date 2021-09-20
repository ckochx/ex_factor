defmodule ExFactor.Util do
  @moduledoc false

  def module_to_string(module) do
    module
    |> Module.split()
    |> Enum.join(".")
  end
end

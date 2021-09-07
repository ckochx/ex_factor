defmodule ExFactor do
  @moduledoc """
  Documentation for `ExFactor`.
  """

  alias ExFactor.Parser, as: P

  def all_fns(input), do: P.all_functions(input)

  def callers(mod) do
    # System.cmd("mix", ["compile"], env: [{"MIX_ENV", "test"}])
    System.cmd("mix", ["xref", "callers",  "#{mod}"], env: [{"MIX_ENV", "test"}])
    # |> IO.inspect(label: "")
    # mix xref callers mod
  end
end

defmodule ExFactor.Callers do
  @moduledoc """
  Documentation for `ExFactor.Callers`.
  """

  alias ExFactor.Parser

  def all_fns(input), do: Parser.all_functions(input)

  @doc """
  use `mix xref` list all the callers of a given module.
  """
  def callers(mod) do
    System.cmd("mix", ["xref", "callers", "#{mod}"], env: [{"MIX_ENV", "test"}])
    |> elem(0)
    |> String.trim()
    |> String.split("\n")
    |> mangle_list()
  end

  defp mangle_list(["Compiling" <> _ | tail]), do: mangle_list(tail)

  defp mangle_list(list) do
    Enum.map(list, fn string ->
      [path, type] = String.split(string, " ")
      %{filepath: path, dependency_type: type}
    end)
  end
end

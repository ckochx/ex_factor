defmodule ExFactor.Callers do
  @moduledoc """
  Documentation for `ExFactor.Callers`.
  """
  import ExUnit.CaptureIO

  alias ExFactor.Parser

  def all_fns(input), do: Parser.all_functions(input)

  @doc """
  use `mix xref` list all the callers of a given module.
  """
  def callers(mod) do
    capture_io(fn -> Mix.Tasks.Xref.run(["callers", mod]) end)
    |> String.trim()
    |> String.split("\n")
    |> mangle_list()
  end

  defp mangle_list([""]), do: []
  defp mangle_list(["Compiling" <> _ | tail]), do: mangle_list(tail)

  defp mangle_list(list) do
    Enum.map(list, fn string ->
      [path, type] = String.split(string, " ")
      %{filepath: path, dependency_type: type}
    end)
  end
end

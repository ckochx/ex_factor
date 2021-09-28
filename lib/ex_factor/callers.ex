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

  def callers(mod, func, arity) do
    Mix.Tasks.Xref.calls([])
    |> Enum.filter(fn x ->
      x.callee == {cast(mod), cast(func), arity}
    end)
  end

  def cast(value) when is_atom(value), do: value

  def cast(value) do
    cond do
      String.downcase(value) == value ->
        String.to_atom(value)

      true ->
        cast_module(value)
    end
  end

  def cast_module(module) do
    if String.match?(module, ~r/Elixir\./) do
      module
    else
      "Elixir." <> module
    end
    |> Module.split()
    |> Module.concat()
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

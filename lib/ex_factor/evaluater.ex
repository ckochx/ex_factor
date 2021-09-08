defmodule ExFactor.Evaluater do
  @moduledoc """
  Documentation for `ExFactor.Evaluater`.
  """

  alias ExFactor.Callers
  alias ExFactor.Parser

  def modules_to_refactor(module, func, arity) do
    module
    |> Callers.callers()
    |> Enum.map(fn %{filepath: filepath} ->
      filepath
      |> Parser.public_functions()
      |> evaluate_ast(filepath, func, arity)
    end)
    |> Enum.reject(&is_nil(&1))
  end

  defp evaluate_ast({_ast, fns}, filepath, func, arity) do
    fns
    |> Enum.find(fn map -> map.name == func && map.arity == arity end)
    |> case do
      nil -> nil
      _ -> filepath
    end
  end
end

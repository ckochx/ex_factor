defmodule ExFactor.Neighbors do
  @moduledoc """
  Documentation for `ExFactor.Neighbors`.
  """

  @doc """
  Walk the AST and find all the elements before the target function and the previous function.
  Find all the instances of the target function. Return after evaluating all the block-level
  AST elements. Ignore certain elements, such as :alias.
  """
  def walk(block, fn_name, arity \\ :unmatched) do
    block
    |> Enum.reduce({[], []}, fn el, acc ->
      eval_elem(el, acc, fn_name, arity)
    end)
    |> elem(1)
  end

  defp eval_elem({type, _, [{name, _, args} | _]} = el, {pending, acc}, name, arity)
       when type in [:def, :defp] do
    cond do
      arity == :unmatched ->
        {[], acc ++ pending ++ [el]}

      length(args) == arity ->
        {[], acc ++ pending ++ [el]}

      true ->
        {[], acc}
    end
  end

  defp eval_elem({type, _, _}, {_pending, acc}, _name, _arity) when type in [:def, :defp] do
    {[], acc}
  end

  defp eval_elem({type, _, _}, {pending, acc}, _name, _artiy) when type in [:alias] do
    {pending, acc}
  end

  defp eval_elem(el, {pending, acc}, _name, _artiy) do
    {pending ++ [el], acc}
  end
end

defmodule ExFactor.Neighbors do
  @moduledoc """
  Documentation for `ExFactor.Neighbors`.
  """

  def prev(block, fn_name) do
    block
    |> Enum.reduce({[], []}, fn el, acc ->
      eval_elem(el, acc, fn_name)
    end)
    |> elem(1)
  end

  defp eval_elem({type, _, [{name, _, _} | _]} = el, {pending, acc}, name)
       when type in [:def, :defp] do
    {[], acc ++ pending ++ [el]}
  end

  defp eval_elem({type, _, _}, {_pending, acc}, _name) when type in [:def, :defp] do
    {[], acc}
  end

  defp eval_elem({type, _, _}, {pending, acc}, _name) when type in [:alias] do
    {pending, acc}
  end

  defp eval_elem(el, {pending, acc}, _name) do
    {pending ++ [el], acc}
  end
end

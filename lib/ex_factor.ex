defmodule ExFactor do
  @moduledoc """
  Documentation for `ExFactor`.
  """

  @doc """
  Identify public functions from a module AST.
  """
  def public_functions({:ok, ast}) do
    # Macro.prewalk(ast, [], fn node, acc ->
    #   # walk_ast(node, acc, :def)
    #   {node, walk_ast(node, acc, :def)}
    #   # |> IO.inspect(label: "walk_ast")
    # end)

    Macro.postwalk(ast, [], fn node, acc ->
      # walk_ast(node, acc, :def)
      {node, walk_ast(node, acc, :def)}
      # |> IO.inspect(label: "walk_ast")
    end)
  end

  def private_functions({:ok, ast}) do
    # Macro.prewalk(ast, [], fn node, acc ->
    #   # walk_ast(node, acc, :def)
    #   {node, walk_ast(node, acc, :def)}
    #   # |> IO.inspect(label: "walk_ast")
    # end)

    Macro.postwalk(ast, [], fn node, acc ->
      # walk_ast(node, acc, :def)
      {node, walk_ast(node, acc, :defp)}
      # |> IO.inspect(label: "walk_ast")
    end)
  end

  defp walk_ast({tkn, _, [{name, _meta, _args} | _]} = func, acc, token) when tkn == token do
    # func |> IO.inspect(label: "walk func TOKEN: #{token}")
    map = %{name: name, ast: func}
    [map | acc]
  end

  defp walk_ast(_func, acc, _token) do
    # func |> IO.inspect(label: "walk fallback token: #{token}")
    acc
    # |> IO.inspect(label: "fallback accum")
  end
end

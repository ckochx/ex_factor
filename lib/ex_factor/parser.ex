defmodule ExFactor.Parser do
  @moduledoc """
  Documentation for `ExFactor`.
  """

  @doc """
  Identify public and private functions from a module AST.
  """
  def all_functions({:ok, _ast} = input) do
    {_ast, public_functions} = public_functions(input)
    {ast, private_functions} = private_functions(input)
    {ast, public_functions ++ private_functions}
  end

  @doc """
  Identify public functions from a module AST.
  """
  def public_functions({:ok, ast}) do
    Macro.postwalk(ast, [], fn node, acc ->
      {node, walk_ast(node, acc, :def)}
    end)
  end

  @doc """
  Identify private functions from a module AST.
  """
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

  defp walk_ast({tkn, _, [{name, _meta, args} | _]} = func, acc, token) when tkn == token do
    arity = length(args)
    map = %{name: name, ast: func, arity: arity, defn: token}
    [map | acc]
  end

  defp walk_ast(_func, acc, _token) do
    acc
  end
end

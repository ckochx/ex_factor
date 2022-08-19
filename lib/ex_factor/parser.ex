defmodule ExFactor.Parser do
  @moduledoc """
  `ExFactor.Parser` we're making some assumptions that you're using this library within the
  context of a Mix app and that every file contains one or more `defmodule` blocks.
  """

  @doc """
  Parse the contents of a filepath in an Abstract Syntaxt Tree (AST) and
  extraxct the block contents of the module at the filepath.
  """
  def read_file(filepath) when is_binary(filepath) do
    contents = File.read!(filepath)
    list = String.split(contents, "\n")
    {:ok, ast} = Code.string_to_quoted(contents, token_metadata: true)
    {ast, list}
  end

  def block_contents(filepath) when is_binary(filepath) do
    filepath
    |> File.read!()
    |> Code.string_to_quoted(token_metadata: true)
    |> block_contents()
  end

  def block_contents({:ok, ast}) do
    Macro.postwalk(ast, [], fn node, acc ->
      {node, ast_block(node, acc)}
    end)
  end

  @doc """
  Identify public and private functions from a module AST.
  """
  def all_functions(filepath) when is_binary(filepath) do
    filepath
    |> File.read!()
    |> Code.string_to_quoted([:line, token_metadata: true, columns: true])
    |> all_functions()
  end

  def all_functions({:ok, _ast} = input) do
    {_ast, public_functions} = public_functions(input)
    {ast, private_functions} = private_functions(input)
    all_fns = public_functions ++ private_functions
    {ast, Enum.uniq(all_fns)}
  end

  @doc """
  Identify public functions from a module AST.
  """
  def public_functions(filepath) when is_binary(filepath) do
    filepath
    |> File.read!()
    |> Code.string_to_quoted([:line, token_metadata: true, columns: true])
    |> public_functions()
  end

  def public_functions({:ok, ast}) do
    Macro.postwalk(ast, [], fn node, acc ->
      {node, walk_ast(node, acc, :def)}
    end)
  end

  @doc """
  Identify private functions from a module AST.
  """
  def private_functions(filepath) when is_binary(filepath) do
    filepath
    |> File.read!()
    |> Code.string_to_quoted([:line, token_metadata: true, columns: true])
    |> private_functions()
  end

  def private_functions({:ok, ast}) do
    Macro.postwalk(ast, [], fn node, acc ->
      {node, walk_ast(node, acc, :defp)}
    end)
  end

  defp walk_ast({:@, _, [{:doc, _meta, _} | _]} = node, acc, _token) do
    map = %{name: :doc, ast: node, arity: 0, defn: "@doc"}
    [map | acc]
  end

  defp walk_ast(
         {:@, fn_meta, [{:spec, _meta, [{_, _, [{name, _, args} | _]} | _]} | _]} = node,
         acc,
         _token
       ) do
    arity = length(args)
    map = merge_maps(%{name: name, ast: node, arity: arity, defn: "@spec"}, fn_meta)
    [map | acc]
  end

  defp walk_ast(
         {tkn, fn_meta, [{:when, _when_meta, [{name, _meta, args} | _]} | _]} = node,
         acc,
         token
       )
       when tkn == token do
    arity = length(args)
    map = merge_maps(%{name: name, ast: node, arity: arity, defn: token}, fn_meta)
    [map | acc]
  end

  defp walk_ast({tkn, fn_meta, [{name, _meta, args} | _]} = node, acc, token) when tkn == token do
    arity = length(args)
    map = merge_maps(%{name: name, ast: node, arity: arity, defn: token}, fn_meta)
    [map | acc]
  end

  defp walk_ast(_node, acc, _token) do
    acc
  end

  defp merge_maps(map, meta) do
    meta
    |> find_lines()
    |> Map.merge(map)
  end

  defp find_lines(meta) do
    start_line = Keyword.get(meta, :line, :unknown)
    end_line = find_end_line(meta)
    %{start_line: start_line, end_line: end_line}
  end

  defp find_end_line(meta) do
    end_expression_line =
      meta
      |> Keyword.get(:end_of_expression, [])
      |> Keyword.get(:line, :unknown)

    end_line =
      meta
      |> Keyword.get(:end, [])
      |> Keyword.get(:line, :unknown)

    cond do
      end_line != :unknown -> end_line
      end_expression_line != :unknown -> end_expression_line
      true -> :unknown
    end
  end

  defp ast_block([do: {:__block__, [], block_contents}], _acc) do
    block_contents
  end

  defp ast_block([do: block_contents], _acc) do
    [block_contents]
  end

  defp ast_block(_block, acc) do
    acc
  end
end

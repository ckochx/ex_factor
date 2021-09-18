defmodule ExFactor.Remover do
  @moduledoc """
  Documentation for `ExFactor.Remover`.
  """

  alias ExFactor.Parser

  @doc """
  Remove the indicated function and its spec from it's original file.
  """
  def remove(opts) do
    source_function = Keyword.fetch!(opts, :source_function)
    source_module = Keyword.get(opts, :source_module)
    arity = Keyword.fetch!(opts, :arity)
    source_path = Keyword.get(opts, :source_path, path(source_module))
    dry_run = Keyword.get(opts, :dry_run, false)

    {_ast, block_contents} = Parser.all_functions(source_path)
    fns_to_remove = Enum.filter(block_contents, &(&1.name == source_function))
    {_ast, line_list} = Parser.read_file(source_path)

    Enum.reduce(fns_to_remove, line_list, fn function, acc ->
      delete_range =
        function.start_line..function.end_line
        |> Enum.to_list()
        |> Enum.reverse()

      delete_range
      |> Enum.reduce(acc, fn idx, acc ->
        List.delete_at(acc, idx - 1)
      end)
      |> List.insert_at(function.start_line, comment(source_function, arity, function.defn))
    end)
    |> Enum.join("\n")
    |> then(fn str -> write_file(source_path, str, source_module, dry_run) end)
  end

  defp comment(name, arity, "@spec") do
    """
    # @spec: #{name}/#{arity} removed by ExFactor
    """
  end

  defp comment(name, arity, _) do
    """
    #
    # Function: #{name}/#{arity} removed by ExFactor
    # ExFactor only removes the function itself
    # Other artifacts, including docs and module-level comments
    # may remain for you to remove manually.
    #
    """
  end

  defp write_file(path, contents, source_module, true) do
    %{
      module: source_module,
      path: path,
      message: "--dry_run changes to make",
      file_contents: contents
    }
  end

  defp write_file(path, contents, _source_module, _) do
    File.write(path, contents, [:write])
  end

  defp path(module) do
    Path.join(["lib", Macro.underscore(module) <> ".ex"])
  end
end

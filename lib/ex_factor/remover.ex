defmodule ExFactor.Remover do
  @moduledoc """
  Documentation for `ExFactor.Remover`.
  """

  alias ExFactor.Parser

  def remove(source_path, fn_name, arity) do
    {_ast, block_contents} = Parser.all_functions(source_path)
    fns_to_remove = Enum.filter(block_contents, &(&1.name == fn_name))
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
      |> List.insert_at(function.start_line, comment(fn_name, arity, function.defn))
    end)
    |> Enum.join("\n")
    |> then(fn str -> File.write(source_path, str, [:write]) end)
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
end

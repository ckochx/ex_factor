defmodule ExFactor.Remover do
  @moduledoc """
  `ExFactor.Remover` Remove the indicated function and its spec from it's original file.

  It's safer to add rather than remove multiple attributes.
  """
  alias ExFactor.Parser

  @doc """
  Remove the indicated function and its spec from it's original file.
  """
  def remove(opts) do
    source_function =
      opts
      |> Keyword.fetch!(:source_function)
      |> function_name()

    source_module = Keyword.get(opts, :source_module)

    arity = Keyword.fetch!(opts, :arity)
    source_path = Keyword.get(opts, :source_path, path(source_module))
    dry_run = Keyword.get(opts, :dry_run, false)
    guard_mismatch!(source_module, source_path)

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
      |> List.insert_at(function.start_line - 1, comment(source_function, arity, function.defn))
    end)
    |> Enum.join("\n")
    |> then(fn str -> write_file(fns_to_remove, source_path, str, source_module, dry_run) end)
  end

  defp guard_mismatch!(module_string, source_path) when is_binary(module_string) do
    source_path
    |> File.read!()
    |> String.match?(~r/#{module_string}/)
    |> unless do
      raise ArgumentError,
            "Module name: #{module_string} not detected in source path: '#{source_path}'"
    end
  end

  defp guard_mismatch!(source_module, source_path) do
    module_string = Module.split(source_module) |> Enum.join(".")
    guard_mismatch!(module_string, source_path)
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
    # Other artifacts such as test references and module-level comments
    # may remain for you to remove manually.
    #
    """
  end

  defp write_file(_, path, contents, source_module, true) do
    %ExFactor{
      module: source_module,
      path: path,
      state: [:dry_run],
      message: "--dry_run changes to make",
      file_contents: contents
    }
  end

  defp write_file([], path, contents, source_module, _) do
    %ExFactor{
      module: source_module,
      path: path,
      state: [:unchanged],
      message: "function not matched",
      file_contents: contents
    }
  end

  defp write_file(_, path, contents, source_module, _) do
    File.write(path, contents, [:write])

    %ExFactor{
      module: source_module,
      path: path,
      state: [:removed],
      message: "changes made",
      file_contents: contents
    }
  end

  defp path(module), do: ExFactor.path(module)

  defp function_name(name) when is_binary(name) do
    String.to_atom(name)
  end

  defp function_name(name), do: name
end

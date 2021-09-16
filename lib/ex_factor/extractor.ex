defmodule ExFactor.Extractor do
  @moduledoc """
  Documentation for `ExFactor.Extractor`.
  """
  alias ExFactor.Neighbors
  alias ExFactor.Parser
  alias ExFactor.Remover

  @doc """
  Given a keyword list of opts, find the function in the specified source.
  Add the function (and any accociated attrs: @doc, @spec, ) into the target module. refactor it, the docs,
  specs, and any miscellaneous attrs proximate to the source function into the specified module.
  """

  def emplace(opts) do
    source_module = Keyword.get(opts, :source_module)
    target_module = Keyword.get(opts, :target_module)
    source_function = Keyword.get(opts, :source_function)
    arity = Keyword.get(opts, :arity)
    target_path = Keyword.get(opts, :target_path, path(target_module))
    source_path = Keyword.get(opts, :source_path, path(source_module))
    {_ast, block_contents} = Parser.block_contents(source_path)
    to_extract = Neighbors.walk(block_contents, source_function, arity)

    case File.exists?(target_path) do
      true ->
        {ast, list} = Parser.read_file(target_path)
        {:defmodule, [do: [line: _begin_line], end: [line: end_line], line: _], _} = ast
        string_fns = Macro.to_string(to_extract)

        list
        |> List.insert_at(end_line - 1, refactor_message())
        |> List.insert_at(end_line, string_fns)
        |> Enum.join("\n")
        |> then(fn contents -> File.write(target_path, contents, [:write]) end)

      _ ->
        content =
          quote generated: true do
            defmodule unquote(target_module) do
              @moduledoc false
              unquote(to_extract)
            end
          end
          |> Macro.to_string()

        File.write(target_path, content)
    end
  end

  @doc """
  Remove the indicated function and its spec from it's original file.
  """
  def remove(opts) do
    source_module = Keyword.get(opts, :source_module)
    source_function = Keyword.get(opts, :source_function)
    arity = Keyword.get(opts, :arity)
    source_path = Keyword.get(opts, :source_path, path(source_module))

    Remover.remove(source_path, source_function, arity)
  end

  defp path(module) do
    Path.join(["lib", Macro.underscore(module) <> ".ex"])
  end

  defp refactor_message, do: "#refactored function moved with ExFactor"
end

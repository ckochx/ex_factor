defmodule ExFactor.Extractor do
  @moduledoc """
  Documentation for `ExFactor.Extractor`.
  """
  alias ExFactor.Neighbors
  alias ExFactor.Parser

  def emplace(opts) do
    source_module = Keyword.get(opts, :source_module)
    target_module = Keyword.get(opts, :target_module)
    source_function = Keyword.get(opts, :source_function)
    arity = Keyword.get(opts, :arity)
    target_path = Keyword.get(opts, :target_path, path(target_module))
    source_path = Keyword.get(opts, :source_path, path(source_module))
    {ast, block_contents} = Parser.block_contents(source_path)
    to_extract = Neighbors.prev(block_contents, source_function)

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

  defp path(module) do
    Path.join(["lib", Macro.underscore(module) <> ".ex"])
  end

  defp refactor_message, do: "#refactored function moved with ExFactor"
end

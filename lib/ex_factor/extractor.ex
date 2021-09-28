defmodule ExFactor.Extractor do
  @moduledoc """
  Documentation for `ExFactor.Extractor`.
  """
  alias ExFactor.Neighbors
  alias ExFactor.Parser

  @doc """
  Given a keyword list of opts, find the function in the specified source.
  Add the function (and any accociated attrs: @doc, @spec, ) into the target module. refactor it, the docs,
  specs, and any miscellaneous attrs proximate to the source function into the specified module.

  Required keys:
    - :source_module
    - :target_module
    - :source_function
    - :arity

  Optional keys:
    - :source_path Specify an alternate (non-standard) path for the source module
    - :target_path Specify an alternate (non-standard) path for the destination module
    - :dry_run Don't write any updates
  """

  def emplace(opts) do
    # modules as strings
    source_module = Keyword.fetch!(opts, :source_module)
    target_module = Keyword.fetch!(opts, :target_module)
    source_function = Keyword.fetch!(opts, :source_function)
    arity = Keyword.fetch!(opts, :arity)
    target_path = Keyword.get(opts, :target_path, path(target_module))
    source_path = Keyword.get(opts, :source_path, path(source_module))
    dry_run = Keyword.get(opts, :dry_run, false)
    {_ast, block_contents} = Parser.block_contents(source_path)

    to_extract =
      block_contents
      |> Neighbors.walk(source_function, arity)
      |> Enum.map(&Macro.to_string(&1))

    string_fns = Enum.join(to_extract, "\n")

    case File.exists?(target_path) do
      true ->
        {ast, list} = Parser.read_file(target_path)
        {:defmodule, [do: [line: _begin_line], end: [line: end_line], line: _], _} = ast

        list
        |> List.insert_at(end_line - 1, refactor_message())
        |> List.insert_at(end_line, string_fns)
        |> Enum.join("\n")
        |> then(fn contents -> write_file(target_path, contents, target_module, dry_run) end)

      _ ->
        target_mod = Module.concat([target_module])

        quote generated: true do
          defmodule unquote(target_mod) do
            @moduledoc false
            unquote(Macro.unescape_string(string_fns))
          end
        end
        |> Macro.to_string()
        |> then(fn contents -> write_file(target_path, contents, target_module, dry_run) end)
    end
  end

  defp path(module), do: ExFactor.path(module)

  defp refactor_message, do: "#refactored function moved with ExFactor"

  defp write_file(target_path, contents, module, true) do
    %{
      module: module,
      path: target_path,
      state: [:dry_run],
      message: "--dry_run changes to make",
      file_contents: contents
    }
  end

  defp write_file(target_path, contents, module, _dry_run) do
    _ = File.write(target_path, contents, [:write])

    %{
      module: module,
      path: target_path,
      state: [:additions_made],
      message: "changes made",
      file_contents: contents
    }
  end
end

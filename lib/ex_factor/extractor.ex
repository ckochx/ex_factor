defmodule ExFactor.Extractor do
  @moduledoc """
  Documentation for `ExFactor.Extractor`.
  """
  alias ExFactor.Parser

  def emplace(files, opts) do
    source_path = Keyword.get(opts, :source_path)
    source_module = Keyword.get(opts, :source_module)
    target_module = Keyword.get(opts, :target_module)
    target_path = Keyword.get(opts, :target_path)
    source_function = Keyword.get(opts, :source_function)
    arity = Keyword.get(opts, :arity)
    target_function = Keyword.get(opts, :target_function, source_function)

    Macro.underscore(source_module)
    # target_path = Macro.underscore(target_module) <> ".ex"
    Path.join([Mix.Project.app_path(), target_path])
    # |> IO.inspect(label: "")

    File.exists?(source_path) |> IO.inspect(label: "")

    {_ast, functions} = Parser.public_functions(source_path)

    map = Enum.find(functions, &(&1.name == source_function && &1.arity == arity))
    # |> IO.inspect(label: "source function")

    # map.ast
    # |> Macro.to_string()
    # |> IO.inspect(label: "source AST")

    case File.exists?(target_path) do
      true ->
        "somehow we need to add the fn to this file"

      _ ->
        content =
          quote generated: true do
            defmodule unquote(target_module) do
              @moduledoc false
              unquote(map.ast)
            end
          end
          |> Macro.to_string()

        # |> IO.inspect(label: "quoted")

        File.write(target_path, content)
    end
  end
end

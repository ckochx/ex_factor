defmodule ExFactor.Extractor do
  @moduledoc """
  Documentation for `ExFactor.Extractor`.
  """
  alias ExFactor.Parser

  def emplace(files, opts) do
    source_module = Keyword.get(opts, :source_module)
    target_module = Keyword.get(opts, :target_module)
    source_function = Keyword.get(opts, :source_function)
    arity = Keyword.get(opts, :arity)
    target_function = Keyword.get(opts, :target_function, source_function)
    target_path = Keyword.get(opts, :target_path, path(target_module))
    source_path = Keyword.get(opts, :source_path, path(source_module))
    {_ast, functions} = Parser.public_functions(source_path)
    # ast |> IO.inspect(label: "")
    map = Enum.find(functions, &(&1.name == source_function && &1.arity == arity))

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

  defp path(module) do
    Path.join(["lib", Macro.underscore(module) <> ".ex"])
  end
end

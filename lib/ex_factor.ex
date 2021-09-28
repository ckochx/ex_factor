defmodule ExFactor do
  @moduledoc """
  `ExFactor` is a refactoring helper.

  By identifying a Module, function name, and arity, it will identify all non-test usages
  and extract them to a new Module.

  If the Module exists, it add the function to the end of the file and change all calls to the
  new module's name.
  """

  _docp = "results struct"
  defstruct [:module, :path, :message, :file_contents, :state]

  alias ExFactor.Changer
  alias ExFactor.Extractor
  alias ExFactor.Formatter
  alias ExFactor.Remover

  @doc """
  Call Extractor, Remover, and Formatter modules
  """
  def refactor(opts) do
    source_module = Keyword.fetch!(opts, :source_module)
    target_module = Keyword.fetch!(opts, :target_module)

    opts =
      opts
      |> Keyword.put_new(:target_path, path(target_module))
      |> Keyword.put_new(:source_path, path(source_module))

    emplace = Extractor.emplace(opts)
    changes = Changer.change(opts)
    # remove should be last (before format)
    removals = Remover.remove(opts)

    format(%{additions: emplace, changes: changes, removals: removals})
  end

  def path(module) do
    Path.join(["lib", Macro.underscore(module) <> ".ex"])
  end

  defp format(%{path: nil} = struct), do: struct

  defp format(%{additions: adds, changes: changes, removals: removals} = output) do
    %{
      additions: format(adds),
      changes: format(changes),
      removals: format(removals)
    }
    output
  end

  defp format(list) when is_list(list) do
    Enum.map(list, fn elem ->
      format(elem)
      Map.get_and_update(elem, :state, fn val -> {val, [:formatted | val]} end)
    end)
  end

  defp format(struct) do
    Formatter.format([struct.path])
    Map.get_and_update(struct, :state, fn val -> {val, [:formatted | val]} end)
  end
end

defmodule ExFactor do
  @moduledoc """
  `ExFactor` is a refactoring helper.

  By identifying a source module, function name, and arity, it will identify all non-test usages
  and extract them to the target module.

  If the target module exists, it adds the function to the end of the file and changes all calls to the
  new module namespace. Otherwise ExFactor will create the target module at the target_path or
  at a (resonably) expected location by the module namespace
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
    dry_run = Keyword.get(opts, :dry_run, false)

    opts =
      opts
      |> Keyword.put_new(:target_path, path(target_module))
      |> Keyword.put_new(:source_path, path(source_module))

    emplace = Extractor.emplace(opts)
    changes = Changer.change(opts)
    # remove should be last (before format)
    removals = Remover.remove(opts)

    format(%{additions: emplace, changes: changes, removals: removals}, dry_run, opts)
  end

  def refactor_module(opts) do
    source_module = Keyword.fetch!(opts, :source_module)
    target_module = Keyword.fetch!(opts, :target_module)
    dry_run = Keyword.get(opts, :dry_run, false)

    opts =
      opts
      |> Keyword.put_new(:target_path, path(target_module))
      |> Keyword.put_new(:source_path, path(source_module))

    changes = Changer.rename_module(opts)

    format(%{additions: %ExFactor{}, changes: changes, removals: %ExFactor{}}, dry_run, opts)
  end

  def path(module) do
    Path.join(["lib", Macro.underscore(module) <> ".ex"])
  end

  defp format(%{path: nil} = struct, _dry_run, _format), do: struct

  defp format(output, true, _format), do: output

  defp format(%{additions: adds, changes: changes, removals: removals} = output, false, opts) do
    %{
      additions: format(adds, opts),
      changes: format(changes, opts),
      removals: format(removals, opts)
    }

    output
  end

  defp format(list, opts) when is_list(list) do
    Enum.map(list, fn elem ->
      format(elem, opts)
      Map.get_and_update(elem, :state, fn val -> {val, [:formatted | val]} end)
    end)
  end

  defp format(%{state: [:unchanged]} = struct, _opts), do: struct

  defp format(struct, opts) do
    Formatter.format([struct.path], opts)
    Map.get_and_update(struct, :state, fn val -> {val, [:formatted | val]} end)
  end
end

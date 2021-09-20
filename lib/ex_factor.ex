defmodule ExFactor do
  @moduledoc """
  `ExFactor` is a refactoring helper.

  By identifying a Module, function name, and arity, it will identify all non-test usages
  and extract them to a new Module.

  If the Module exists, it add the function to the end of the file and change all calls to the
  new module's name.
  """

  alias ExFactor.Changer
  alias ExFactor.Extractor
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
    remove = Remover.remove(opts)
    _changes = Changer.change(opts)
    |> IO.inspect(label: "")
    {emplace, remove}
  end

  def path(module) do
    Path.join(["lib", Macro.underscore(module) <> ".ex"])
  end
end

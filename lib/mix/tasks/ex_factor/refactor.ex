defmodule Mix.Tasks.ExFactor.Refactor do
  @shortdoc """
  Refactor a module, function, and arity to a new module namespace. Find or create the new module as appropriate.
  Required command line args: --module, --function, --arity, --target. (See additional explantion in: #{__MODULE__})
  """

  @moduledoc """
  `ExFactor` is a refactoring helper.

  By identifying a Module, function name, and arity, it will identify all non-test usages
  and extract them to a new Module.

  If the Module exists, it adds the refactored function to the end of the file and change all calls to the
  new module's name. If the Module does not exist ExFactor will conditionally create the path and the module
  and the refactored function will be added to the new module.

  Required command line args: --module, --function, --arity, --target.
    - `:module` is the fully-qualified source module containing the function to move.
    - `:function` is the name of the function (as a string)
    - `:arity` the arity of function to move.
    - `:target` is the fully-qualified destination for the removed function. If the moduel does not exist, it will be created.

  Optional command line args: --source_path, --target_path
    - `:target_path` Specify an alternate (non-standard) path for the source file.
    - `:source_path` Specify an alternate (non-standard) path for the destination file.

  """

  use Mix.Task

  def run(argv) do
    {opts, _extra_opts} = OptionParser.parse(argv, switches: [arity: :integer, module: :string, function: :string, target: :string, key: :string])
    |> IO.inspect(label: "OptionParser")
    # opts = Mix.shell().info(Enum.join(argv, " "))
    opts
    |> IO.inspect(label: "PARSED ARGS")

    # Mix.Task.run("app.start")

    ExFactor.refactor(opts)
  end
end

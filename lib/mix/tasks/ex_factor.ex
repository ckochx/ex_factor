defmodule Mix.Tasks.ExFactor do
  @shortdoc """
  Refactor a module, function, and arity to a new module namespace. Find or create the new module as appropriate.
  Required command line args: --module, --function, --arity, --target.
  `mix help ex_factor` for additional options
  See additional explantion in: #{__MODULE__}
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

  Optional command line args: --source_path, --target_path, --dryrun, --verbose
    - `:target_path` Specify an alternate (non-standard) path for the source file.
    - `:source_path` Specify an alternate (non-standard) path for the destination file.
    - `:dryrun` Don't write any updates, only return the built results.
    - `:verbose` (Default false) include the :state and :file_contents key values.
    - `:format` (Default true) when false don't run the formatter

  Example Usage:
  ```
  mix ex_factor --module MyModule.ToChange --function fn_to_change
  --arity 2 --target YourModule.ChangeTo
  ```

  Example Usage:
  ```
  mix ex_factor --module MyModule.ToChange --function fn_to_change
    --arity 2 --target YourModule.ChangeTo
    --no-format --no-dryrun --no-verbose
  ```
  """

  use Mix.Task

  def run(argv) do
    {parsed_opts, _, _} =
      OptionParser.parse(argv,
        strict: [
          arity: :integer,
          dryrun: :boolean,
          verbose: :boolean,
          format: :boolean,
          function: :string,
          key: :string,
          module: :string,
          moduleonly: :boolean,
          source_path: :string,
          target: :string,
          target_path: :string
        ]
      )

    parsed_opts
    |> options()
    |> choose_your_path()
    |> cli_output(parsed_opts)
  end

  defp choose_your_path(opts) do
    if Keyword.get(opts, :moduleonly, false) do
      ExFactor.refactor_module(opts)
    else
      opts
      |> Keyword.put(:source_function, Keyword.fetch!(opts, :function))
      |> ExFactor.refactor()
    end
  end

  defp options(opts) do
    opts
    |> Keyword.put(:source_module, Keyword.fetch!(opts, :module))
    |> Keyword.put(:target_module, Keyword.fetch!(opts, :target))
    |> Keyword.put(:dry_run, Keyword.get(opts, :dryrun, false))
  end

  defp cli_output(map, opts) do
    verbose = Keyword.get(opts, :verbose, false)

    format_entry(Map.get(map, :additions), "Additions", :light_cyan_background, verbose)
    format_entry(Map.get(map, :changes), "Changes", :light_green_background, verbose)
    format_entry(Map.get(map, :removals), "Removals", :light_red_background, verbose)
    message(false)
  end

  defp format_entry(entry, title, color, verbose) do
    IO.puts(IO.ANSI.format([color, IO.ANSI.format([:black, title])]))

    IO.puts(
      IO.ANSI.format([
        color,
        IO.ANSI.format([
          :black,
          "================================================================================"
        ])
      ])
    )

    IO.puts(
      IO.ANSI.format([
        color,
        IO.ANSI.format([
          :black,
          "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
        ])
      ])
    )

    handle_entry(entry, color, verbose)

    IO.puts(
      IO.ANSI.format([
        color,
        IO.ANSI.format([
          :black,
          "================================================================================"
        ])
      ])
    )

    IO.puts("")
  end

  defp handle_entry(entries, color, verbose) when is_list(entries) do
    Enum.map(entries, &handle_entry(&1, color, verbose))
  end

  defp handle_entry(entry, color, true) do
    handle_entry(entry, color, false)
    IO.puts("  File contents: \n#{entry.file_contents}")
    IO.puts("  State: #{inspect(entry.state)}")
  end

  defp handle_entry(entry, color, false) do
    IO.puts(IO.ANSI.format([color, IO.ANSI.format([:black, "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"])]))
    IO.puts(IO.ANSI.format([color, IO.ANSI.format([:black, "  Module: #{entry.module}"])]))
    IO.puts(IO.ANSI.format([color, IO.ANSI.format([:black, "  Path: #{entry.path}"])]))
    IO.puts(IO.ANSI.format([color, IO.ANSI.format([:black, "  Message: #{entry.message}"])]))
  end

  @message """
  `ExFactor` (by design), does not change test files.

  There are two important and practical reason for this.

  Reason1:
    The test failures provide a safety net to help ensure that the ExFactor-ed functions
    continue to behave as expected.

  Reason2:
    Because .exs files are evaluated at runtime the introspection provided by the compiler
    is not available.

  In future revisions, we hope to address this issue, but for now, refactoring test files
  remains your responsibility.
  """
  defp message(true), do: ""

  defp message(false) do
    IO.puts(
      IO.ANSI.format([
        :magenta_background,
        IO.ANSI.format([
          :bright,
          "⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠"
        ])
      ])
    )

    IO.puts(IO.ANSI.format([:magenta_background, IO.ANSI.format([:bright, "IMPORTANT NOTE:"])]))

    IO.puts(
      IO.ANSI.format([
        :magenta_background,
        IO.ANSI.format([
          :bright,
          "✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖✖"
        ])
      ])
    )

    IO.puts(
      IO.ANSI.format([
        :magenta_background,
        IO.ANSI.format([
          :bright,
          "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        ])
      ])
    )

    IO.puts(IO.ANSI.format([:magenta_background, IO.ANSI.format([:bright, ""])]))
    IO.puts(IO.ANSI.format([:magenta_background, IO.ANSI.format([:bright, @message])]))
  end
end

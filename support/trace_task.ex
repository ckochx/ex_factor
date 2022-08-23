defmodule Mix.Tasks.ExFactorRunner do
  @moduledoc """
  In order to run ExFactor on ExFactor, we need to make some files available "outside of"
  ExFactor, or more precisely along side of ExFactor.

  We need to have a process running during compilation that can run the `ExFactor.Server` Agent.
  Additionally we need the setup from `ExFactor.Traces`, we could replicate this here, but why
  bother copying something that we'll reuse.
  """
  use Mix.Task

  @impl true
  def run(args) do
    unless Version.match?(System.version(), ">= 1.13.0") do
      Mix.raise("Elixir v1.13+ is required!")
    end

    Code.compile_file("./lib/ex_factor/server.ex", File.cwd!())
    :timer.sleep(20)

    Code.compile_file("./lib/ex_factor/traces.ex", File.cwd!())
    :timer.sleep(20)

    case args do
      [] ->

        do_run()

      _ ->
        Mix.raise("Additional CLI args are not supported.\n\n\tUsage: elixir -r support/trace_task.ex -S mix ex_factor_runner")
    end
  end

  defp do_run() do
    ExFactor.Traces.setup()

    Mix.Task.rerun("compile", ["--force", "--tracer=ExFactor.Tracer"]) |> IO.inspect(label: "")

    entries = ExFactor.Server.entries()
    entries_string = inspect(entries, limit: :infinity, printable_limit: :infinity)
    File.write!("./tmp/trace_entries", entries_string)

    file_contents = [
      "defmodule ExFactor.Support.Trace do",
      "def trace_function do",
      entries_string,
      "end",
      "end"
    ]
    |> Enum.join("\n")

    path = "./test/support/trace.ex"
    File.write!(path, file_contents)
    Mix.Tasks.Format.run([path])
  end
end

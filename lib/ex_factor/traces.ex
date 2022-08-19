defmodule ExFactor.Traces do
  def setup do
    Code.compiler_options(debug_info: true, parser_options: [columns: true, token_metadata: true])
    ExFactor.Server = Code.ensure_loaded!(ExFactor.Server)
    ExFactor.Tracer = Code.ensure_loaded!(ExFactor.Tracer)

    _ = ExFactor.Server.start_link(__MODULE__)
  end

  def trace do
    :ok = Application.ensure_loaded(:ex_factor)
    setup()
    Mix.Task.rerun("compile", ["--force", "--tracer=ExFactor.Tracer"])

    ExFactor.Server.entries
  end
end
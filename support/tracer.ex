defmodule ExFactor.Tracer do
  @trace_types ~w(import imported_function alias alias_expansion alias_reference require struct_expansion remote_function local_function)a
  def trace({type, meta, module, name, arity}, env)  when type in @trace_types do
    ExFactor.Server.record(type, env.file, meta[:line], meta[:column], module, name, arity, env.module)
  end

  def trace(_event, _env) do
    :ok
  end
end

import Config

config :ex_factor, ExFactor.Callers,
  trace_function: &ExFactor.Support.Trace.trace_function/0

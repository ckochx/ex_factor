defmodule ExFactor.Server do
  use Agent

  def start_link(_module) do
    Agent.start_link(fn -> %{module: __MODULE__, entries: %{}} end, name: __MODULE__)
  end

  def record(type, file, line, column, module, name, arity, _context_modules, caller_module) do
    Agent.update(__MODULE__, fn state ->
      entry = {type, line, column, module, name, arity}

      Map.update!(state, :entries, fn entries ->
        Map.update(entries, {file, caller_module}, [entry], &[entry | &1])
      end)
    end)
  end

  def entries() do
    Agent.get(__MODULE__, & &1.entries)
  end
end

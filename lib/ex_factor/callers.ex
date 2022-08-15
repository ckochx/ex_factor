defmodule ExFactor.Callers do
  @moduledoc """
  Documentation for `ExFactor.Callers`.
  """
  import ExUnit.CaptureIO

  @doc """
  use `mix xref` list all the callers of a given module.
  """
  def callers(mod, trace_function \\ get_trace_function()) do
    entries = trace_function.()

    callers = fn -> Mix.Tasks.Xref.run(["callers", mod]) end
    |> capture_io()
    |> String.split("\n")

    paths = Enum.map(callers, fn line ->
      Regex.run(~r/\S.*\.ex*\S/, line)
      |> case do
        [path] -> path
        other -> other
      end
    end)

    Enum.filter(entries, fn {{path, _module}, _fn_calls} = _tuple ->
      rel_path = Path.relative_to(path, File.cwd!())

      rel_path in paths
    end)
  end

  def trace_function do
    ExFactor.Traces.trace()
  end

  def callers(mod, func, arity, trace_function \\ get_trace_function()) do
    entries = trace_function.()
    mod = cast(mod)
    func = cast(func)

    callers = fn -> Mix.Tasks.Xref.run(["callers", mod]) end
    |> capture_io()
    |> String.split("\n")

    paths = Enum.map(callers, fn line ->
      Regex.run(~r/\S.*\.ex*\S/, line)
      |> case do
        [path] -> path
        other -> other
      end
    end)

    Enum.filter(entries, fn {{path, _module}, fn_calls} = _tuple ->
      rel_path = Path.relative_to(path, File.cwd!())
      funs = Enum.filter(fn_calls, fn
        {_, _, _, ^mod, ^func, ^arity} -> true
        _ -> false
      end)

      rel_path in paths and match?([_ | _ ], funs)
    end)
  end

  def cast(value) when is_atom(value), do: value

  def cast(value) do
    cond do
      String.downcase(value) == value ->
        String.to_atom(value)

      true ->
        cast_module(value)
    end
  end

  def cast_module(module) do
    if String.match?(module, ~r/Elixir\./) do
      module
    else
      "Elixir." <> module
    end
    |> Module.split()
    |> Module.concat()
  end

  defp get_trace_function do
    :ex_factor
    |> Application.get_env(__MODULE__, trace_function: &ExFactor.Callers.trace_function/0)
    |> Keyword.fetch!(:trace_function)
  end
end

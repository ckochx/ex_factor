defmodule ExFactor.Callers do
  @moduledoc """
  Documentation for `ExFactor.Callers`.
  """
  import ExUnit.CaptureIO

  alias ExFactor.Parser

  def all_fns(input), do: Parser.all_functions(input)

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

  def callers(mod, func, arity) do
    Mix.Tasks.Xref.calls([])
    # |> IO.inspect(label: "callers/3 XREF calls")
    |> Enum.filter(fn x ->
      x.callee == {cast(mod), cast(func), arity}
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

  # defp mangle_list([""]), do: []
  # defp mangle_list(["Compiling" <> _ | tail]), do: mangle_list(tail)

  # defp mangle_list(list) do
  #   Enum.map(list, fn string ->
  #     [path, type] = String.split(string, " ")

  #     %{
  #       file: path,
  #       dependency_type: type
  #     }
  #   end)
  # end

  defp get_trace_function do
    :ex_factor
    |> Application.get_env(__MODULE__, trace_function: &ExFactor.Callers.trace_function/0)
    |> Keyword.fetch!(:trace_function)
  end
end

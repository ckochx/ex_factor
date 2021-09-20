defmodule ExFactor.Changer do
  @moduledoc """
  Documentation for `ExFactor.Changer`.
  """

  alias ExFactor.Callers
  alias ExFactor.Util

  @doc """
  Given all the Callers to a module, find the instances of the target function and refactor the
  function module reference to the new module. Respect any existing aliases.
  """
  def change(opts) do
    source_module = Keyword.fetch!(opts, :source_module)
    Mix.Tasks.Compile.Elixir.run([])

    source_module
    |> Callers.callers()
    |> update_callers(opts)
  end

  defp update_callers([], _), do: []

  defp update_callers(callers, opts) do
    Enum.map(callers, fn caller ->
      File.read!(caller.filepath)
      |> String.split("\n")
      |> find_and_replace_target(opts, caller.filepath)
    end)
  end

  defp find_and_replace_target(list, opts, filepath) do
    # opts values
    source_module = Keyword.fetch!(opts, :source_module)
    source_function = Keyword.fetch!(opts, :source_function)
    target_module = Keyword.fetch!(opts, :target_module)
    _arity = Keyword.fetch!(opts, :arity)
    dry_run = Keyword.get(opts, :dry_run, false)

    # modified values
    source_string = Util.module_to_string(source_module)
    source_modules = String.split(source_module, ".")
    source_alias = Enum.at(source_modules, -1)
    target_alias = preferred_alias(list, target_module)
    source_alias_alt = find_alias_as(list, source_module)

    Enum.reduce(list, {:unchanged, []}, fn elem, {state, acc} ->
      cond do
        String.match?(elem, ~r/#{source_string}\.#{source_function}/) ->
          elem = String.replace(elem, source_module, target_module)
          {:changed, [elem | acc]}

        String.match?(elem, ~r/#{source_alias}\.#{source_function}/) ->
          elem = String.replace(elem, source_alias, target_alias)
          {:changed, [elem | acc]}

        String.match?(elem, ~r/#{source_alias_alt}\.#{source_function}/) ->
          elem = String.replace(elem, source_alias_alt, target_alias)
          {:changed, [elem | acc]}

        true ->
          {state, [elem | acc]}
      end
    end)
    |> maybe_add_alias(opts)
    |> write_file(source_function, filepath, dry_run)
  end

  defp find_alias_as(list, module) do
    aalias = Enum.find(list, "", fn el -> el =~ "alias #{Util.module_to_string(module)}" end)

    if String.match?(aalias, ~r/, as: /) do
      aalias
      |> String.split("as:", trim: true)
      |> Enum.at(-1)
    else
      ""
    end
  end

  defp preferred_alias(list, target_module) do
    target_modules = String.split(target_module, ".")
    target_alias = Enum.at(target_modules, -1)
    target_alias_alt = find_alias_as(list, target_module)

    if target_alias_alt == "" do
      target_alias
    else
      target_alias_alt
    end
  end

  defp write_file({:unchanged, contents_list}, source_function, target_path, true) do
    %{
      path: target_path,
      state: [:unchanged],
      message: "#{source_function} not found, no changes to make",
      file_contents: list_to_string(contents_list)
    }
  end

  defp write_file({state, contents_list}, _, target_path, true) do
    %{
      path: target_path,
      state: [:dry_run, state],
      message: "--dry_run changes to make",
      file_contents: list_to_string(contents_list)
    }
  end

  defp write_file({state, contents_list}, _, target_path, _dry_run) do
    contents = list_to_string(contents_list)
    File.write(target_path, contents, [:write])

    %{
      path: target_path,
      state: [state],
      message: "changes made",
      file_contents: contents
    }
  end

  defp list_to_string(contents_list) do
    contents_list
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp maybe_add_alias({:unchanged, contents_list}, _), do: {:unchanged, contents_list}

  defp maybe_add_alias({state, contents_list}, opts) do
    source_module = Keyword.fetch!(opts, :source_module)
    source_string = Util.module_to_string(source_module)
    target_module = Keyword.fetch!(opts, :target_module)
    target_string = Util.module_to_string(target_module)

    if Enum.find(contents_list, fn el -> el =~ "alias #{target_string}" end) do
      {state, contents_list}
    else
      contents_list
      |> Enum.reduce([], fn elem, acc ->
        if elem =~ "alias #{source_string}" do
          new_alias = String.replace(elem, source_string, target_string)
          [new_alias | [elem | acc]]
        else
          [elem | acc]
        end
      end)
      |> Enum.reverse()
      |> then(fn list -> {state, list} end)
    end
  end
end

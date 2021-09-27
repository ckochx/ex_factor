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
    Mix.Tasks.Compile.Elixir.run([])
    :timer.sleep(100)
    source_module = Keyword.fetch!(opts, :source_module)
    source_function = Keyword.fetch!(opts, :source_function)
    arity = Keyword.fetch!(opts, :arity)

    source_module
    |> Callers.callers(source_function, arity)
    |> Enum.group_by(& &1.file)
    |> update_caller_groups(opts)
  end

  defp update_caller_groups(empty_map, opts) when empty_map == %{},
    do: update_caller_groups([], opts)

  defp update_caller_groups([], opts) do
    source_module = Keyword.fetch!(opts, :source_module)
    [%ExFactor{state: [:unchanged], message: "module: #{source_module} not found"}]
  end

  defp update_caller_groups(callers, opts) do
    dry_run = Keyword.get(opts, :dry_run, false)
    source_function = Keyword.fetch!(opts, :source_function)

    Enum.map(callers, fn {file, callers} ->
      file_list =
        File.read!(file)
        |> String.split("\n")

      callers
      |> Enum.reduce({:unchanged, file_list}, fn %{line: line}, acc ->
        find_and_replace_function(acc, opts, line)
      end)
      |> maybe_add_alias(opts)
      |> maybe_add_import(opts)
      |> write_file(source_function, file, dry_run)
    end)
  end

  defp find_and_replace_function({state, file_list}, opts, line) do
    # opts values
    source_module = Keyword.fetch!(opts, :source_module)
    source_function = Keyword.fetch!(opts, :source_function)
    target_module = Keyword.fetch!(opts, :target_module)

    # modified values
    source_string = Util.module_to_string(source_module)
    source_modules = String.split(source_module, ".")
    source_alias = Enum.at(source_modules, -1)
    target_alias = preferred_alias(file_list, target_module)
    source_alias_alt = find_alias_as(file_list, source_module)
    fn_line = Enum.at(file_list, line - 1)

    {new_state, new_line} =
      cond do
        # match full module name
        String.match?(fn_line, ~r/#{source_string}\.#{source_function}/) ->
          fn_line = String.replace(fn_line, source_module, target_alias)
          {:changed, fn_line}

        # match aliased module name
        String.match?(fn_line, ~r/#{source_alias}\.#{source_function}/) ->
          fn_line = String.replace(fn_line, source_alias, target_alias)
          {:changed, fn_line}

        # match module name aliased :as
        String.match?(fn_line, ~r/#{source_alias_alt}\.#{source_function}/) ->
          fn_line = String.replace(fn_line, source_alias_alt, target_alias)
          {:changed, fn_line}

        true ->
          {state, fn_line}
      end

    {new_state, List.replace_at(file_list, line - 1, new_line)}
  end

  defp find_alias_as(list, module) do
    aalias = Enum.find(list, "", fn el -> str_match?(el, module) end)

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

  defp write_file({state, contents_list}, _, target_path, true) do
    %ExFactor{
      path: target_path,
      state: [:dry_run | [state]],
      message: "--dry_run changes to make",
      file_contents: list_to_string(contents_list)
    }
  end

  defp write_file({state, contents_list}, _, target_path, _dry_run) do
    contents = list_to_string(contents_list)
    File.write(target_path, contents, [:write])

    %ExFactor{
      path: target_path,
      state: state,
      message: "changes made",
      file_contents: contents
    }
  end

  defp list_to_string(contents_list) do
    Enum.join(contents_list, "\n")
  end

  defp maybe_add_alias({state, contents_list}, opts) do
    source_module = Keyword.fetch!(opts, :source_module)
    source_string = Util.module_to_string(source_module)
    target_module = Keyword.fetch!(opts, :target_module)
    target_string = Util.module_to_string(target_module)

    # when module has no aliases
    contents_list =
      if Enum.find(contents_list, fn el -> str_match?(el, "") end) do
        contents_list
      else
        List.insert_at(contents_list, 1, "alias #{target_string}")
      end

    if Enum.find(contents_list, fn el -> str_match?(el, target_string) end) do
      {state, contents_list}
    else
      contents_list
      |> Enum.reduce({:none, []}, fn elem, {prev, acc} ->
        cond do
          str_match?(elem, source_string) ->
            new_alias = String.replace(elem, source_string, target_string)
            {:alias, [elem | [new_alias | acc]]}

          prev == :alias and not str_match?(elem, "") ->
            {:alias_added, [elem | ["alias #{target_string}" | acc]]}

          str_match?(elem, "") ->
            {state, [elem | acc]}

          true ->
            {state, [elem | acc]}
        end
      end)
      |> then(fn {state, list} -> {state, Enum.reverse(list)} end)
    end
  end

  defp maybe_add_import({state, contents_list}, opts) do
    source_module = Keyword.fetch!(opts, :source_module)
    target_module = Keyword.fetch!(opts, :target_module)
    target_string = Util.module_to_string(target_module)
    source_modules = String.split(source_module, ".")
    source_alias = Enum.at(source_modules, -1)
    source_alias_alt = find_alias_as(contents_list, source_module)

    # when module has no imports
    index =
      Enum.find_index(contents_list, fn el -> str_match?(el, source_alias, "import") end) ||
        Enum.find_index(contents_list, fn el -> str_match?(el, source_alias_alt, "import") end)

    new_state =
      if state == :unchanged do
        [:import_added]
      else
        [:import_added | [state]]
      end

    if index do
      {new_state, List.insert_at(contents_list, index + 1, "import #{target_string}")}
    else
      {state, contents_list}
    end
  end

  defp str_match?(string, match, token \\ "alias")

  defp str_match?(string, "", token) do
    String.match?(string, ~r/(^|\s)#{token}\s/)
  end

  defp str_match?(string, module_string, token) do
    String.match?(string, ~r/(^|\s)#{token} #{module_string}(\s|$|\,)/)
  end
end

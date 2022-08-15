defmodule ExFactor.Changer do
  @moduledoc """
  `ExFactor.Changer` find all references to the old (source) Mod.function/arity and update
  the calls to use the new (target) Mod.function/arity.
  """

  alias ExFactor.Callers
  alias ExFactor.Parser

  @doc """
  Given all the Callers to a module, find the instances of the target function and refactor the
  function module reference to the new module. Respect any existing aliases.
  """
  def change(opts) do
    source_module = Keyword.fetch!(opts, :source_module)

    source_module
    |> Callers.callers()
    |> update_caller_groups(opts)
  end

  defp update_caller_groups(empty_map, opts) when empty_map == %{},
    do: update_caller_groups([], opts)

  defp update_caller_groups([], opts) do
    source_module = Keyword.fetch!(opts, :source_module)

    [
      %ExFactor{
        state: [:unchanged],
        message: "No additional references to source module: (#{source_module}) detected"
      }
    ]
  end

  defp update_caller_groups(callers, opts) do
    dry_run = Keyword.get(opts, :dry_run, false)
    source_module = Keyword.fetch!(opts, :source_module)
    source_function = Keyword.get(opts, :source_function)
    mod = Callers.cast(source_module)

    case source_function do
      nil -> callers
        Enum.filter(callers, fn {{file_path, module}, fn_calls} ->
          Enum.find(fn_calls, fn
          {_, _, _, ^mod, _, _} -> true
          _ -> false
          end)
        end)
      fun ->
        fun_atom = Callers.cast(fun)
        Enum.filter(callers, fn {{file_path, module}, fn_calls} ->
          Enum.find(fn_calls, fn
          {_, _, _, ^mod, ^fun_atom, _} -> true
          _ -> false
          end)
        end)
    end
    |> Enum.map(fn {{file_path, module}, fn_calls} ->
      file_list =
        file_path
        |> File.read!()
        |> String.split("\n")
      Enum.reduce(fn_calls, {[:unchanged], file_list}, fn
        {_, line, _, ^mod, _, _} = fn_call, acc ->
          find_and_replace(acc, opts, line)
        _, acc -> acc
      end)
      |> maybe_add_alias(opts)
      |> maybe_add_import(opts)
      |> write_file(module, file_path, dry_run)
    end)
  end

  defp find_and_replace({state, file_list} = tuple, opts, line) do
    # opts values
    case Keyword.get(opts, :source_function) do
      nil -> update_module(tuple, opts, line)
      _source_function -> update_module_and_function(tuple, opts, line)
    end
  end

  defp update_module_and_function({state, file_list}, opts, line) do
    # opts values
    source_module = Keyword.fetch!(opts, :source_module)
    target_module = Keyword.fetch!(opts, :target_module)

    # modified values
    source_string = to_string(source_module)
    source_modules = String.split(source_module, ".")
    source_alias = Enum.at(source_modules, -1)
    target_alias = preferred_alias(file_list, target_module)
    source_alias_alt = find_alias_as(file_list, source_module)
    {:ok, source_function} = Keyword.fetch(opts, :source_function)
    fn_line = Enum.at(file_list, line - 1)

    {new_state, new_line} =
      cond do
        # match full module name
        String.match?(fn_line, ~r/#{source_string}\.#{source_function}/) ->
          fn_line = String.replace(fn_line, source_module, target_alias)
          {set_state(state, :changed), fn_line}

        # match aliased module name
        String.match?(fn_line, ~r/#{source_alias}\.#{source_function}/) ->
          fn_line = String.replace(fn_line, source_alias, target_alias)
          {set_state(state, :changed), fn_line}

        # match module name aliased :as
        String.match?(fn_line, ~r/#{source_alias_alt}\.#{source_function}/) ->
          fn_line = String.replace(fn_line, source_alias_alt, target_alias)
          {set_state(state, :changed), fn_line}

        true ->
          {state, fn_line}
      end

    {new_state, List.replace_at(file_list, line - 1, new_line)}
  end

  defp update_module({state, file_list}, opts, line) do
    # opts values
    source_module = Keyword.fetch!(opts, :source_module)
    target_module = Keyword.fetch!(opts, :target_module)

    # modified values
    source_string = to_string(source_module)
    source_modules = String.split(source_module, ".")
    source_alias = Enum.at(source_modules, -1)
    target_alias = preferred_alias(file_list, target_module)
    source_alias_alt = find_alias_as(file_list, source_module)
    fn_line = Enum.at(file_list, line - 1)

    {new_state, new_line} =
      cond do
        # already changed
        String.match?(fn_line, ~r/#{target_alias}/) ->
          {state, fn_line}

        # match full module name
        String.match?(fn_line, ~r/#{source_string}/) ->
          fn_line = String.replace(fn_line, source_module, target_alias)
          {set_state(state, :changed), fn_line}

        # match aliased module name
        String.match?(fn_line, ~r/#{source_alias}/) ->
          fn_line = String.replace(fn_line, source_alias, target_alias)
          {set_state(state, :changed), fn_line}

        true ->
          {state, fn_line}
      end

    {new_state, List.replace_at(file_list, line - 1, new_line)}
  end

  defp find_alias_as(list, module) do
    alias_as = Enum.find(list, "", fn el -> str_match?(el, module) end)

    if String.match?(alias_as, ~r/, as: /) do
      alias_as
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

  defp write_file({state, contents_list}, module, target_path, true) do
    %ExFactor{
      path: target_path,
      state: [:dry_run | state],
      module: module,
      message: "--dry_run changes to make",
      file_contents: list_to_string(contents_list)
    }
  end

  defp write_file({state, contents_list}, module, target_path, _dry_run) do
    contents = list_to_string(contents_list)
    File.write(target_path, contents, [:write])

    %ExFactor{
      path: target_path,
      state: state,
      module: module,
      message: "changes made",
      file_contents: contents
    }
  end

  defp list_to_string(contents_list) do
    Enum.join(contents_list, "\n")
  end
  defp maybe_add_alias({[:unchanged], _} = resp, _), do: resp

  defp maybe_add_alias({state, contents_list}, opts) do
    target_module = Keyword.fetch!(opts, :target_module)
    target_string = to_string(target_module)

    {state, contents_list}
    |> change_alias(target_string)
    |> add_alias(target_string)
    |> then(fn {state, list} -> {state, maybe_reverse(list)} end)
  end

  defp maybe_reverse([head | _tail] = list) do
    if String.match?(head, ~r/defmodule/) do
      list
    else
      Enum.reverse(list)
    end
  end

  defp change_alias({state, contents_list}, target_string) do
    elem = Enum.find(contents_list, &str_match?(&1, target_string, "alias"))

    if elem do
      {[:alias_exists | state], contents_list}
    else
      {state, contents_list}
    end
  end

  defp add_alias({state, contents_list}, target_string) do
    cond do
      :alias_changed in state ->
        {state, contents_list}

      :alias_added in state ->
        {state, contents_list}

      :alias_exists in state ->
        {state, contents_list}

      :changed in state ->
        alias_index =
          Enum.find_index(contents_list, fn el -> str_match?(el, target_string, "alias") end)

        index = alias_index || 2
        contents_list = List.insert_at(contents_list, index - 1, "alias #{target_string}")
        {set_state(state, :alias_added), contents_list}

      true ->
        {state, contents_list}
    end
  end

  defp maybe_add_import({[:unchanged], _} = resp, _), do: resp
  defp maybe_add_import({state, contents_list}, opts) do
    source_module = Keyword.fetch!(opts, :source_module)
    target_module = Keyword.fetch!(opts, :target_module)
    target_alias = preferred_alias([], target_module)
    source_modules = String.split(source_module, ".")
    source_alias = Enum.at(source_modules, -1)
    source_alias_alt = find_alias_as(contents_list, source_module)

    # when module has no imports
    index =
      Enum.find_index(contents_list, fn el -> str_match?(el, source_alias, "import") end) ||
        Enum.find_index(contents_list, fn el -> str_match?(el, source_alias_alt, "import") end)

    if index do
      {set_state(state, :import_added), List.insert_at(contents_list, index + 1, "import #{target_alias}")}
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

  defp set_state([:unchanged], new_state), do: [new_state]
  defp set_state(state, new_state), do: [new_state | state]
end

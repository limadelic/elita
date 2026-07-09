defmodule Elita.Credo.Imports do
  use Credo.Check, category: :refactor, base_priority: :normal

  alias Credo.SourceFile
  alias Credo.Code

  def param_defaults do
    [allowlist: [:ets, :erlang, :rand, :cover, :node]]
  end

  @check_desc "Functions must be imported, not called with Module.func syntax. Aliases (single-segment qualified calls) are OK."
  @param_desc "Erlang modules to allowlist for qualified calls."

  def explanations do
    [check: @check_desc, params: [allowlist: @param_desc]]
  end

  def run(%SourceFile{} = source_file, params) do
    defaults = param_defaults()
    allowlist = Keyword.get(params, :allowlist, Keyword.get(defaults, :allowlist))
    filename = source_file.filename
    Process.put(:elita_imports, [])
    Process.put(:elita_aliases, [])
    Process.put(:elita_local_defs, [])
    Process.put(:elita_import_names, [])
    Code.prewalk(source_file, &check_call(&1, &2, allowlist, filename))
  end

  defp check_call({:import, _meta, [{:__aliases__, _ma, parts} | rest]} = ast, issues, _allowlist, _filename) do
    imports = Process.get(:elita_imports) || []
    Process.put(:elita_imports, [parts | imports])
    collect_import_only_names(rest)
    {ast, issues}
  end

  defp check_call({:alias, _meta, [{:__aliases__, _ma, parts} | rest]} = ast, issues, _allowlist, _filename) do
    alias_name = extract_alias_name(parts, rest)
    aliases = Process.get(:elita_aliases) || []
    Process.put(:elita_aliases, [alias_name | aliases])
    {ast, issues}
  end

  defp check_call({:alias, _meta, [{{:., _dm, [{:__aliases__, _ma, _parts}, :{}]}, _call_meta, children}]} = ast, issues, _allowlist, _filename) do
    aliases = Process.get(:elita_aliases) || []
    new_aliases = Enum.reduce(children, aliases, fn child, acc ->
      case child do
        {:__aliases__, _cm, child_parts} -> [List.last(child_parts) | acc]
        _ -> acc
      end
    end)
    Process.put(:elita_aliases, new_aliases)
    {ast, issues}
  end

  defp check_call({type, _meta, [head | _tail]} = ast, issues, _allowlist, _filename)
       when type in [:def, :defp, :defmacro] do
    func_name = extract_function_name(head)
    if func_name do
      local_defs = Process.get(:elita_local_defs) || []
      Process.put(:elita_local_defs, [func_name | local_defs])
    end
    {ast, issues}
  end

  defp check_call({{:., meta, [module, func]}, _call_meta, _args} = ast, issues, allowlist, filename) do
    if Keyword.get(meta, :generated, false) do
      {ast, issues}
    else
      imports = Process.get(:elita_imports) || []
      aliases = Process.get(:elita_aliases) || []
      local_defs = Process.get(:elita_local_defs) || []
      import_names = Process.get(:elita_import_names) || []
      {ast, maybe_add_issue(module, func, meta, issues, allowlist, imports, aliases, local_defs, import_names, filename)}
    end
  end

  defp check_call(ast, issues, _allowlist, _filename) do
    {ast, issues}
  end

  defp maybe_add_issue({:__MODULE__, _meta1}, _func, _meta2, issues, _allowlist, _imports, _aliases, _local_defs, _import_names, _filename) do
    issues
  end

  defp maybe_add_issue(:__MODULE__, _func, _meta, issues, _allowlist, _imports, _aliases, _local_defs, _import_names, _filename) do
    issues
  end

  defp maybe_add_issue({:__aliases__, _meta_alias, [module]}, _func, meta, issues, allowlist, imports, aliases, _local_defs, _import_names, filename) when is_atom(module) do
    if is_imported?([module], imports) or is_aliased?(module, aliases) or not should_report?(module, allowlist) do
      issues
    else
      [create_issue(module, meta, filename) | issues]
    end
  end

  defp maybe_add_issue({:__aliases__, _meta, parts}, _func, meta, issues, allowlist, imports, aliases, _local_defs, _import_names, filename)
       when is_list(parts) and length(parts) > 1 do
    module_name = Enum.join(Enum.map(parts, &to_string/1), ".")
    if is_imported_nested?(parts, imports) or is_aliased_nested?(parts, aliases) or not should_report_nested(module_name, allowlist) do
      issues
    else
      [create_issue(module_name, meta, filename) | issues]
    end
  end

  defp maybe_add_issue(module, _func, _meta, issues, _allowlist, _imports, _aliases, _local_defs, _import_names, _filename)
       when not is_atom(module) do
    issues
  end

  defp maybe_add_issue(module, _func, meta, issues, allowlist, imports, aliases, _local_defs, _import_names, filename)
       when is_atom(module) do
    if is_imported?([module], imports) or is_aliased?(module, aliases) or not should_report?(module, allowlist) do
      issues
    else
      [create_issue(module, meta, filename) | issues]
    end
  end

  defp is_imported?(parts, imports) do
    Enum.any?(imports, &(&1 == parts))
  end

  defp is_imported_nested?(parts, imports) do
    Enum.any?(imports, &(&1 == parts))
  end

  defp is_aliased?(module, aliases) when is_atom(module) do
    Enum.any?(aliases, &(&1 == module))
  end

  defp is_aliased_nested?(parts, aliases) do
    last_part = List.last(parts)
    Enum.any?(aliases, &(&1 == last_part))
  end

  defp extract_alias_name(parts, rest) do
    case rest do
      [[as: {:__aliases__, _meta, as_parts}]] -> List.last(as_parts)
      [[as: as_atom]] when is_atom(as_atom) -> as_atom
      _ -> List.last(parts)
    end
  end

  defp should_report?(module, allowlist) do
    not is_special_module(module) and not in_allowlist(module, allowlist)
  end

  defp should_report_nested(module_name, allowlist) do
    not String.starts_with?(module_name, ":") and
      not String.starts_with?(module_name, "Elixir.Kernel") and
      not String.starts_with?(module_name, "Elixir.Access") and
      not in_allowlist_string(module_name, allowlist)
  end

  defp in_allowlist_string(module_name, allowlist) do
    Enum.any?(allowlist, fn m ->
      m_str = to_string(m)
      m_str == module_name || ends_with(module_name, m_str)
    end)
  end

  defp ends_with(full_name, part) do
    String.ends_with?(full_name, "." <> part) or String.ends_with?(full_name, part)
  end

  defp is_special_module(module) do
    module_str = to_string(module)
    String.starts_with?(module_str, ":") or module in [:Kernel, :Access] or
      module_str in ["Kernel", "Access", "Elixir.Kernel", "Elixir.Access"]
  end

  defp in_allowlist(module, allowlist) do
    module in allowlist
  end

  defp create_issue(module, meta, filename) do
    msg = "Use import #{module} instead of #{module}.function() calls."
    line = meta[:line]
    col = meta[:column]

    %Credo.Issue{
      category: :refactor,
      exit_status: 2,
      check: __MODULE__,
      message: msg,
      line_no: line,
      column: col,
      priority: :normal,
      filename: filename
    }
  end

  defp extract_function_name({:when, _meta, [func_def | _rest]}), do: extract_function_name(func_def)
  defp extract_function_name({name, _meta, _args}) when is_atom(name), do: name
  defp extract_function_name(_), do: nil

  defp collect_import_only_names(rest) do
    case rest do
      [[only: names]] when is_list(names) ->
        import_names = Process.get(:elita_import_names) || []
        collected = Enum.reduce(names, import_names, fn item, acc ->
          case item do
            {name, _arity} when is_atom(name) -> [name | acc]
            name when is_atom(name) -> [name | acc]
            _ -> acc
          end
        end)
        Process.put(:elita_import_names, collected)
      _ ->
        :ok
    end
  end

end

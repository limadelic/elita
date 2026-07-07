defmodule Elita.Credo.Imports do
  use Credo.Check, category: :refactor, base_priority: :normal

  alias Credo.SourceFile
  alias Credo.Code

  def param_defaults do
    [allowlist: [:ets, :erlang, :rand]]
  end

  @check_desc "Functions must be imported, not called with Module.func syntax. Aliases (single-segment qualified calls) are OK."
  @param_desc "Erlang modules to allowlist for qualified calls."

  def explanations do
    [check: @check_desc, params: [allowlist: @param_desc]]
  end

  def run(%SourceFile{} = source_file, params) do
    allowlist = Keyword.get(params, :allowlist, [:ets, :erlang, :rand])
    filename = source_file.filename
    Code.prewalk(source_file, &check_call(&1, &2, allowlist, filename))
  end

  defp check_call({{:., meta, [module, _func]}, _call_meta, _args} = ast, issues, allowlist, filename) do
    # Skip compiler-generated calls (interpolation, bracket access, etc.)
    if Keyword.get(meta, :generated, false) do
      {ast, issues}
    else
      {ast, maybe_add_issue(module, meta, issues, allowlist, filename)}
    end
  end

  defp check_call(ast, issues, _allowlist, _filename) do
    {ast, issues}
  end

  defp maybe_add_issue({:__MODULE__, _meta1}, _meta2, issues, _allowlist, _filename) do
    issues
  end

  defp maybe_add_issue(:__MODULE__, _meta, issues, _allowlist, _filename) do
    issues
  end

  defp maybe_add_issue({:__aliases__, _meta_alias, [module]}, meta, issues, allowlist, filename) when is_atom(module) do
    if should_report?(module, allowlist) do
      [create_issue(module, meta, filename) | issues]
    else
      issues
    end
  end

  defp maybe_add_issue({:__aliases__, _meta, parts}, meta, issues, allowlist, filename)
       when is_list(parts) and length(parts) > 1 do
    module_name = Enum.join(Enum.map(parts, &to_string/1), ".")
    if should_report_nested(module_name, allowlist) do
      [create_issue(module_name, meta, filename) | issues]
    else
      issues
    end
  end

  defp maybe_add_issue(module, _meta, issues, _allowlist, _filename)
       when not is_atom(module) do
    issues
  end

  defp maybe_add_issue(module, meta, issues, allowlist, filename)
       when is_atom(module) do
    if should_report?(module, allowlist) do
      [create_issue(module, meta, filename) | issues]
    else
      issues
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
end

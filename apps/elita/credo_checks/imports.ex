defmodule Elita.Credo.Imports do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code, only: [prewalk: 2]
  import Elita.Credo.Check

  def param_defaults, do: [allowlist: [:ets, :erlang, :rand, :cover]]

  @check_desc "Functions must be imported, not called with Module.func syntax. Aliases (single-segment qualified calls) are OK."
  @param_desc "Erlang modules to allowlist for qualified calls."

  def explanations do
    [check: @check_desc, params: [allowlist: @param_desc]]
  end

  def run(source_file, params) do
    defaults = param_defaults()
    allowlist = Keyword.get(params, :allowlist, Keyword.get(defaults, :allowlist))
    ctx = %{allowlist: allowlist, filename: source_file.filename}
    prewalk(source_file, &check_call(&1, &2, ctx))
  end

  defp check_call({:import, _meta, [{:__aliases__, _ma, _parts} | _rest]} = ast, issues,
                  _ctx), do: {ast, issues}

  defp check_call({:alias, _meta, [{:__aliases__, _ma, _parts} | _rest]} = ast, issues,
                  _ctx), do: {ast, issues}

  defp check_call({:alias, _meta, [{{:., _dm, [{:__aliases__, _ma, _parts}, :{}]},
                                     _call_meta, _children}]} = ast,
                  issues, _ctx),
       do: {ast, issues}

  defp check_call({type, _meta, [_head | _tail]} = ast, issues, _ctx)
       when type in [:def, :defp, :defmacro], do: {ast, issues}

  defp check_call({{:., meta, [module, _func]}, _call_meta, args} = ast, issues, ctx) do
    cfg = %{generated: Keyword.get(meta, :generated, false), meta: meta, module: module, arity: length(args), ctx: ctx}
    handle_call(ast, issues, cfg)
  end

  defp check_call(ast, issues, _ctx), do: {ast, issues}

  defp handle_call(ast, issues, %{generated: true}), do: {ast, issues}
  defp handle_call(ast, issues, cfg) do
    {ast, check_module(cfg.module, cfg.arity, cfg.meta, issues, cfg.ctx)}
  end

  defp check_module({:__MODULE__, _meta1}, _arity, _meta2, issues, _ctx), do: issues
  defp check_module(:__MODULE__, _arity, _meta, issues, _ctx), do: issues

  defp check_module({:__aliases__, _meta_alias, [module]}, _arity, _meta, issues, _ctx)
       when is_atom(module), do: issues

  defp check_module({:__aliases__, _meta, [_,_|_] = parts}, _arity, meta, issues, ctx) do
    name = Enum.map_join(parts, ".", &to_string/1)
    flag_nested(builtin?(name), name, meta, issues, ctx)
  end

  defp check_module(module, _arity, _meta, issues, _ctx) when not is_atom(module),
       do: issues

  defp check_module(module, _arity, meta, issues, ctx) when is_atom(module) do
    flag_atomic(special?(module), module, meta, issues, ctx)
  end

  defp flag_nested(true, _name, _meta, issues, _ctx), do: issues
  defp flag_nested(false, name, meta, issues, ctx) do
    flag_if_listed(listed?(name, ctx.allowlist), name, meta, issues, ctx)
  end

  defp flag_if_listed(true, _name, _meta, issues, _ctx), do: issues
  defp flag_if_listed(false, name, meta, issues, ctx) do
    [issue(name, meta, ctx.filename) | issues]
  end

  defp flag_atomic(true, _module, _meta, issues, _ctx), do: issues
  defp flag_atomic(false, module, meta, issues, ctx) do
    flag_if_allowed(module in ctx.allowlist, module, meta, issues, ctx)
  end

  defp flag_if_allowed(true, _module, _meta, issues, _ctx), do: issues
  defp flag_if_allowed(false, module, meta, issues, ctx) do
    [issue(module, meta, ctx.filename) | issues]
  end

  defp issue(module, meta, filename) do
    %Credo.Issue{category: :refactor, exit_status: 2, check: __MODULE__,
      message: "Use import #{module} instead of #{module}.function() calls.",
      line_no: meta[:line], column: meta[:column], priority: :normal,
      filename: filename}
  end
end

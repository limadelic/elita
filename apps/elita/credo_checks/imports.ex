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
    prewalk(source_file, &visit(&1, &2, ctx))
  end

  defp visit({:import, _meta, [{:__aliases__, _ma, _parts} | _rest]} = ast, issues,
                  _ctx), do: {ast, issues}

  defp visit({:alias, _meta, [{:__aliases__, _ma, _parts} | _rest]} = ast, issues,
                  _ctx), do: {ast, issues}

  defp visit({:alias, _meta, [{{:., _dm, [{:__aliases__, _ma, _parts}, :{}]},
                                     _call_meta, _children}]} = ast,
                  issues, _ctx),
       do: {ast, issues}

  defp visit({type, _meta, [_head | _tail]} = ast, issues, _ctx)
       when type in [:def, :defp, :defmacro], do: {ast, issues}

  defp visit({{:., meta, [module, _func]}, _call_meta, args} = ast, issues, ctx) do
    cfg = %{generated: Keyword.get(meta, :generated, false), meta: meta, module: module, arity: length(args), ctx: ctx}
    handle_call(ast, issues, cfg)
  end

  defp visit(ast, issues, _ctx), do: {ast, issues}

  defp handle_call(ast, issues, %{generated: true}), do: {ast, issues}
  defp handle_call(ast, issues, cfg) do
    {ast, vet(cfg.module, cfg.arity, cfg.meta, issues, cfg.ctx)}
  end

  defp vet({:__MODULE__, _meta1}, _arity, _meta2, issues, _ctx), do: issues
  defp vet(:__MODULE__, _arity, _meta, issues, _ctx), do: issues

  defp vet({:__aliases__, _meta_alias, [module]}, _arity, _meta, issues, _ctx)
       when is_atom(module), do: issues

  defp vet({:__aliases__, _meta, [_,_|_] = parts}, _arity, meta, issues, ctx) do
    name = Enum.map_join(parts, ".", &to_string/1)
    nest(builtin?(name), name, meta, issues, ctx)
  end

  defp vet(module, _arity, _meta, issues, _ctx) when not is_atom(module),
       do: issues

  defp vet(module, _arity, meta, issues, ctx) when is_atom(module) do
    atom(special?(module), module, meta, issues, ctx)
  end

  defp nest(true, _name, _meta, issues, _ctx), do: issues
  defp nest(false, name, meta, issues, ctx) do
    list(listed?(name, ctx.allowlist), name, meta, issues, ctx)
  end

  defp list(true, _name, _meta, issues, _ctx), do: issues
  defp list(false, name, meta, issues, ctx) do
    [issue(name, meta, ctx.filename) | issues]
  end

  defp atom(true, _module, _meta, issues, _ctx), do: issues
  defp atom(false, module, meta, issues, ctx) do
    allow(module in ctx.allowlist, module, meta, issues, ctx)
  end

  defp allow(true, _module, _meta, issues, _ctx), do: issues
  defp allow(false, module, meta, issues, ctx) do
    [issue(module, meta, ctx.filename) | issues]
  end

  defp issue(module, meta, filename) do
    %Credo.Issue{category: :refactor, exit_status: 2, check: __MODULE__,
      message: "Use import #{module} instead of #{module}.function() calls.",
      line_no: meta[:line], column: meta[:column], priority: :normal,
      filename: filename}
  end
end

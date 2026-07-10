defmodule Elita.Credo.Imports do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code, only: [prewalk: 2]
  import Elita.Credo.Check
  import Keyword, only: [get: 2, get: 3]
  import Enum, only: [map_join: 3]
  import List, only: [first: 1]
  import Map, only: [merge: 2]

  @msg "Please import instead of qualified calls"
  @base %Credo.Issue{
    category: :refactor,
    exit_status: 2,
    message: @msg,
    priority: :normal
  }
  @allow [:ets, :erlang, :rand, :cover]
  @mods [:GenServer, :Supervisor, :Application, :Task, :Node, :Process, :System]

  def param_defaults, do: [allowlist: @allow, modules: @mods]

  def explanations do
    [
      check: "Import functions instead of Module.func qualified calls.",
      params: [allowlist: "Erlang modules allowlist for qualified calls."]
    ]
  end

  def run(src, par) do
    c = cfg(param_defaults(), par, src)
    prewalk(src, &visit(&1, &2, c))
  end

  defp cfg(p, par, src), do: %{allowlist: get(par, :allowlist, get(p, :allowlist)), modules: get(par, :modules, get(p, :modules)), filename: src.filename}

  defp visit({:import, _, _} = ast, issues, _ctx), do: {ast, issues}
  defp visit({:alias, _, _} = ast, issues, _ctx), do: {ast, issues}
  defp visit({t, _, _} = ast, issues, _ctx) when t in [:def, :defp, :defmacro], do: {ast, issues}
  defp visit({{:., _m, [_mod, f]}, _, _} = ast, issues, _ctx) when f in [:get, :fetch, :__access__], do: {ast, issues}
  defp visit({{:., m, [{:__aliases__, _, _}, _]}, _, _} = ast, issues, ctx), do: {ast, scan(ast, m, issues, ctx)}
  defp visit({{:., _, [_mod, _]}, _, _} = ast, issues, _ctx), do: {ast, issues}
  defp visit(ast, issues, _ctx), do: {ast, issues}

  defp scan(ast, m, issues, ctx) do
    skip(get(m, :generated, false), ast, m, issues, ctx)
  end

  defp skip(true, _ast, _m, issues, _ctx), do: issues
  defp skip(false, ast, m, issues, ctx) do
    chk(first(elem(elem(ast, 0), 2)), m, issues, ctx)
  end

  defp chk(:Access, _m, issues, _ctx), do: issues
  defp chk(:Kernel, _m, issues, _ctx), do: issues
  defp chk({:__MODULE__, _}, _m, issues, _ctx), do: issues
  defp chk(:__MODULE__, _m, issues, _ctx), do: issues
  defp chk({:__aliases__, _, [x]}, m, issues, ctx) when is_atom(x), do: single(x, m, issues, ctx)
  defp chk({:__aliases__, _, [_, _ | _] = p}, m, issues, ctx) do
    multi(map_join(p, ".", &to_string/1), m, issues, ctx)
  end
  defp chk(x, _m, issues, _ctx) when not is_atom(x), do: issues
  defp chk(x, m, issues, ctx) when is_atom(x), do: single(x, m, issues, ctx)

  defp single(x, _m, issues, _ctx) when x in [:Kernel, :Access], do: issues
  defp single(x, m, issues, ctx), do: ok(x in ctx.modules, m, issues, ctx)

  defp ok(true, _m, issues, _ctx), do: issues
  defp ok(false, m, issues, ctx), do: [flag(m, ctx) | issues]

  defp multi(n, _m, issues, _ctx) when n in ["Kernel", "Access"], do: issues
  defp multi(n, m, issues, ctx), do: buil(builtin?(n), n, m, issues, ctx)

  defp buil(true, _n, _m, issues, _ctx), do: issues
  defp buil(false, n, m, issues, ctx), do: pend(listed?(n, ctx.allowlist), m, issues, ctx)

  defp pend(true, _m, issues, _ctx), do: issues
  defp pend(false, m, issues, ctx), do: [flag(m, ctx) | issues]

  defp flag(m, c), do: @base |> merge(%{check: __MODULE__, line_no: m[:line], column: m[:column], filename: c.filename})
end

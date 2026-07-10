defmodule Elita.Credo.Names do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code, only: [prewalk: 2]
  import Keyword, only: [get: 3]
  import Enum, only: [filter: 2, map: 2, reverse: 1, member?: 2, concat: 2]
  import Elita.Credo.Check, only: [compound?: 1]
  import String, only: [starts_with?: 2, contains?: 2, trim_trailing: 2]
  import Map, only: [put: 3, merge: 2]

  @check "Module and function names should use single-word segments."
  @base %Credo.Issue{category: :refactor, exit_status: 2, priority: :normal}
  @msg_mod "Module segment is compound; use single words."
  @msg_fun "Function is compound; use single words."
  @allow [
    :param_defaults, :explanations, :init, :terminate, :handle_call,
    :handle_cast, :handle_info, :start_link, :start, :stop,
    :child_spec, :format_status, :moduledoc, :doc
  ]

  def explanations, do: [check: @check]
  def run(file, params) do
    allow = get(params, :allowlist, []) ++ @allow
    prewalk(file, &check(&1, &2, file.filename, allow))
  end
  defp check({:defmodule, meta, [{:__aliases__, _ma, parts} | _rest]} = ast, issues, filename, _allow),
    do: {ast, compose(parts, meta, filename, issues)}
  defp check({:def, meta, [{name, _meta, args} | _rest]} = ast, issues, filename, allow) when is_atom(name) do
    issues2 = params(args, issues, filename)
    visit({ast, issues2, meta, name, filename, allow})
  end
  defp check({:defmacro, meta, [{name, _meta, args} | _rest]} = ast, issues, filename, allow) when is_atom(name) do
    issues2 = params(args, issues, filename)
    visit({ast, issues2, meta, name, filename, allow})
  end
  defp check({:defp, meta, [{name, _meta, args} | _rest]} = ast, issues, filename, _allow) when is_atom(name) do
    issues2 = params(args, issues, filename)
    visit({ast, issues2, meta, name, filename, []})
  end
  defp check({:=, meta, [lhs, _rhs]} = ast, issues, filename, _allow),
    do: {ast, capture(lhs, issues, filename, meta)}
  defp check(ast, issues, _filename, _allow), do: {ast, issues}
  defp compose(parts, meta, filename, issues) do
    m = &issue("#{&1}: #{@msg_mod}", meta, filename)
    parts |> filter(&compound?/1) |> map(m) |> reverse() |> concat(issues)
  end
  defp visit({ast, issues, meta, name, filename, allow}),
    do: result(state(name, allow), {ast, meta, name, filename, issues})
  defp state(name, allow),
    do: flag(member?(allow, name), starts_with?("#{name}", "_"), snake?("#{name}"))
  defp flag(false, false, true), do: true
  defp flag(_, _, _), do: false
  defp result(true, {ast, meta, name, filename, issues}),
    do: {ast, [issue("#{name}: #{@msg_fun}", meta, filename) | issues]}
  defp result(false, {ast, _meta, _name, _filename, issues}), do: {ast, issues}
  defp snake?(s), do: s |> trim_trailing("?!") |> contains?("_")
  defp params(args, issues, filename) when is_list(args) do
    args |> filter(&hidden?/1) |> map(&blame(&1, filename)) |> concat(issues)
  end
  defp params(_, issues, _filename), do: issues
  defp hidden?({name, _meta, nil}) when is_atom(name) do
    snake?("#{name}") |> judge(starts_with?("#{name}", "_"))
  end
  defp hidden?(_), do: false
  defp judge(true, false), do: true
  defp judge(_, _), do: false
  defp blame({name, meta, nil}, filename),
    do: issue("#{name}: Parameter is compound; use single words.", meta, filename)
  defp capture({name, _meta, nil}, issues, filename, meta) when is_atom(name) do
    ok(snake?("#{name}"), name, issues, filename, meta)
  end
  defp capture(_, issues, _filename, _meta), do: issues
  defp ok(true, name, issues, filename, meta) do
    [issue("#{name}: Variable is compound; use single words.", meta, filename) | issues]
  end
  defp ok(false, _name, issues, _filename, _meta), do: issues

  defp issue(msg, meta, filename),
    do: @base |> put(:check, __MODULE__) |> merge(attrs(msg, meta, filename))

  defp attrs(msg, meta, filename) do
    %{message: msg, line_no: meta[:line],
      column: meta[:column], filename: filename}
  end
end

defmodule Elita.Credo.Names do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code, only: [prewalk: 2]

  @check_desc "Module and function names should use single-word segments (e.g. Tape, Play, run, flag; not TapeHandler, check_call)."
  @base %Credo.Issue{category: :refactor, exit_status: 2, priority: :normal}
  @allow [
    :param_defaults, :explanations, :init, :terminate,
    :handle_call, :handle_cast, :handle_info,
    :start_link, :start, :stop, :child_spec
  ]

  def explanations do
    [check: @check_desc]
  end

  def run(source_file, params) do
    allow = Keyword.get(params, :allowlist, []) ++ @allow
    filename = source_file.filename
    prewalk(source_file, &check(&1, &2, filename, allow))
  end

  defp check({:defmodule, meta, [{:__aliases__, _ma, parts} | _rest]} = ast, issues, filename, _allow) do
    {ast, compose(parts, meta, filename, issues)}
  end

  defp check({:def, meta, [{name, _meta, _args} | _rest]} = ast, issues, filename, allow)
       when is_atom(name) do
    visit({ast, issues, meta, name, filename, allow})
  end

  defp check({:defp, meta, [{name, _meta, _args} | _rest]} = ast, issues, filename, allow)
       when is_atom(name) do
    visit({ast, issues, meta, name, filename, allow})
  end

  defp check({:defmacro, meta, [{name, _meta, _args} | _rest]} = ast, issues, filename, allow)
       when is_atom(name) do
    visit({ast, issues, meta, name, filename, allow})
  end

  defp check(ast, issues, _filename, _allow) do
    {ast, issues}
  end

  defp compose(parts, meta, filename, issues) do
    parts |> Enum.filter(&compound?/1) |> mod(meta, filename) |> Enum.reverse() |> Enum.concat(issues)
  end

  defp mod(parts, meta, filename) do
    Enum.map(parts, &segment(&1, meta, filename))
  end
  defp segment(seg, meta, filename) do
    msg = "Module segment '#{seg}' is compound. Use single words only (e.g. Tape, Play, not TapeHandler)."
    issue(msg, meta, filename)
  end

  defp visit({ast, issues, meta, name, filename, allow}) do
    result(state(name, allow), {ast, meta, name, filename, issues})
  end
  defp state(name, allow) do
    string = Atom.to_string(name)
    flag(Enum.member?(allow, name), String.starts_with?(string, "_"), snake?(string))
  end

  defp flag(false, false, true), do: true
  defp flag(_, _, _), do: false
  defp result(true, {ast, meta, name, filename, issues}) do
    msg =
      "Function '#{name}' is compound. Use single words only (e.g. run, flag, not check_call)."

    {ast, [issue(msg, meta, filename) | issues]}
  end

  defp result(false, {ast, _meta, _name, _filename, issues}) do
    {ast, issues}
  end
  defp snake?(s) do
    name_without_suffix = String.trim_trailing(s, "?!")
    String.contains?(name_without_suffix, "_")
  end

  defp compound?(segment) do
    segment |> str() |> word?()
  end
  defp str(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp str(s), do: s

  defp word?(s) when not is_binary(s), do: false
  defp word?(s) when byte_size(s) == 0, do: false
  defp word?(s), do: pattern(Regex.match?(~r/^[A-Z][a-z]+[A-Z]/, s), s)
  defp pattern(false, _s), do: false
  defp pattern(true, s), do: String.upcase(s) != s

  defp issue(msg, meta, filename) do
    base = Map.put(@base, :check, __MODULE__)
    Map.merge(base, %{message: msg, line_no: meta[:line], column: meta[:column], filename: filename})
  end
end

defmodule Elita.Credo.Names do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code, only: [prewalk: 2]

  @check_desc "Module names should use single-word segments (e.g. Tape, Play, Miss, not TapeHandler, ShippedTape)."

  def explanations do
    [check: @check_desc]
  end

  def run(source_file, _params) do
    filename = source_file.filename
    prewalk(source_file, &check_module(&1, &2, filename))
  end

  defp check_module({:defmodule, meta, [{:__aliases__, _ma, parts} | _rest]} = ast, issues, filename) do
    new_issues = parts |> Enum.filter(&is_compound_word/1) |> Enum.map(&create_issue(&1, meta, filename)) |> Enum.reverse() |> Enum.concat(issues)
    {ast, new_issues}
  end

  defp check_module(ast, issues, _filename) do
    {ast, issues}
  end

  defp is_compound_word(segment) do
    segment |> maybe_to_string() |> check_compound()
  end

  defp maybe_to_string(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp maybe_to_string(s), do: s

  defp check_compound(s) when not is_binary(s), do: false
  defp check_compound(s) when byte_size(s) == 0, do: false
  defp check_compound(s) do
    check_pattern(Regex.match?(~r/^[A-Z][a-z]+[A-Z]/, s), s)
  end

  defp check_pattern(false, _s), do: false
  defp check_pattern(true, s), do: String.upcase(s) != s

  defp create_issue(segment, meta, filename) do
    msg = "Module segment '#{segment}' is compound. Use single words only (e.g. Tape, Play, not TapeHandler)."
    make_issue(msg, meta, filename)
  end

  defp make_issue(msg, meta, filename) do
    %Credo.Issue{category: :refactor, exit_status: 2, check: __MODULE__,
      message: msg, line_no: meta[:line], column: meta[:column],
      priority: :normal, filename: filename}
  end
end

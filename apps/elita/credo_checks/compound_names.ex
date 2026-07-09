defmodule Elita.Credo.CompoundNames do
  use Credo.Check, category: :refactor, base_priority: :normal

  alias Credo.SourceFile
  alias Credo.Code

  @check_desc "Module names should use single-word segments (e.g. Tape, Play, Miss, not TapeHandler, ShippedTape)."

  def explanations do
    [check: @check_desc]
  end

  def run(%SourceFile{} = source_file, _params) do
    filename = source_file.filename
    Code.prewalk(source_file, &check_module(&1, &2, filename))
  end

  defp check_module({:defmodule, meta, [{:__aliases__, _ma, parts} | _rest]} = ast, issues, filename) do
    new_issues = Enum.reduce(parts, issues, fn segment, acc ->
      if is_compound_word(segment) do
        [create_issue(segment, meta, filename) | acc]
      else
        acc
      end
    end)
    {ast, new_issues}
  end

  defp check_module(ast, issues, _filename) do
    {ast, issues}
  end

  defp is_compound_word(segment) when is_atom(segment) do
    segment_str = Atom.to_string(segment)
    is_compound_word(segment_str)
  end

  defp is_compound_word(segment_str) when is_binary(segment_str) do
    # Detect CamelCase with multiple humps: uppercase followed by lowercase followed by uppercase
    # E.g., TapeHandler matches, but Tape, Handler, DSR do not
    # Pattern: [A-Z][a-z]+[A-Z] means compound
    # All-caps (DSR) and single words pass
    case segment_str do
      "" ->
        false

      s ->
        not is_all_caps(s) and Regex.match?(~r/^[A-Z][a-z]+[A-Z]/, s)
    end
  end

  defp is_all_caps(s) do
    String.upcase(s) == s
  end

  defp create_issue(segment, meta, filename) do
    msg = "Module segment '#{segment}' is compound. Use single words only (e.g. Tape, Play, not TapeHandler)."
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

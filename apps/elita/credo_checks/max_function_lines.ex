defmodule Elita.Credo.MaxFunctionLines do
  use Credo.Check, category: :refactor, base_priority: :normal

  alias Credo.SourceFile
  alias Credo.Code
  alias Elita.Credo.LineCheck

  def param_defaults do
    [max_lines: 5, exclude: []]
  end

  @check_desc "Functions should be small and focused."
  @param_desc "The maximum number of lines a function body can have."

  def explanations do
    [check: @check_desc, params: [max_lines: @param_desc]]
  end

  def run(%SourceFile{} = source_file, params) do
    max_lines = Keyword.get(params, :max_lines, 5)
    exclude = Keyword.get(params, :exclude, [])
    filename = source_file.filename
    Code.prewalk(source_file, &check_function(&1, &2, max_lines, filename, exclude))
  end

  defp check_function({type, meta, [_head | _tail]} = ast, issues, max_lines, filename, exclude)
       when type in [:def, :defp, :defmacro] do
    if excluded?(filename, exclude) do
      {ast, issues}
    else
      {ast, maybe_add_issue(max_lines, meta, issues, filename)}
    end
  end

  defp check_function(ast, issues, _max_lines, _filename, _exclude) do
    {ast, issues}
  end

  defp excluded?(filename, exclude) do
    Enum.any?(exclude, fn mod ->
      name = mod |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
      path = name |> String.replace(".", "/") |> String.downcase()
      String.contains?(filename, path)
    end)
  end

  defp maybe_add_issue(max_lines, meta, issues, filename) do
    meta
    |> LineCheck.find_body_lines()
    |> add_issue(max_lines, meta, issues, filename)
  end

  defp add_issue({:ok, lines}, max, meta, issues, filename)
       when lines > max do
    [create_issue(lines, max, meta, filename) | issues]
  end

  defp add_issue(_, _, _, issues, _filename), do: issues

  defp create_issue(body_lines, max_lines, meta, filename) do
    LineCheck.issue_for(__MODULE__, "Function", body_lines, max_lines, {meta, filename})
  end
end

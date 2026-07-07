defmodule Elita.Credo.MaxModuleLines do
  use Credo.Check, category: :refactor, base_priority: :normal

  alias Credo.SourceFile
  alias Credo.Code
  alias Elita.Credo.LineCheck

  def param_defaults do
    [max_lines: 100]
  end

  @check_desc "Modules should be reasonably sized and focused."
  @param_desc "The maximum number of lines a module body can have."

  def explanations do
    [check: @check_desc, params: [max_lines: @param_desc]]
  end

  def run(%SourceFile{} = source_file, params) do
    max_lines = Keyword.get(params, :max_lines, 100)
    filename = source_file.filename
    source = File.read!(filename)
    Code.prewalk(source_file, &check_module(&1, &2, max_lines, filename, source))
  end

  defp check_module({:defmodule, meta, [_ | _]} = ast, issues, max_lines, filename, source) do
    {ast, maybe_add_issue(max_lines, meta, issues, filename, source)}
  end

  defp check_module(ast, issues, _max_lines, _filename, _source) do
    {ast, issues}
  end

  defp maybe_add_issue(max_lines, meta, issues, filename, source) do
    meta
    |> LineCheck.find_body_lines(source)
    |> add_issue(max_lines, meta, issues, filename)
  end

  defp add_issue({:ok, lines}, max, meta, issues, filename)
       when lines > max do
    [create_issue(lines, max, meta, filename) | issues]
  end

  defp add_issue({:ok, _}, _, _, issues, _), do: issues
  defp add_issue(:error, _, _, issues, _), do: issues

  defp create_issue(body_lines, max_lines, meta, filename) do
    LineCheck.issue_for(__MODULE__, "Module", body_lines, max_lines, {meta, filename})
  end
end

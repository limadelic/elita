defmodule Elita.Credo.Modlines do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code, only: [prewalk: 2]
  import Elita.Credo.Lines

  def param_defaults do
    [max_lines: 100]
  end

  @check_desc "Modules should be reasonably sized and focused."
  @param_desc "The maximum number of lines a module body can have."

  def explanations do
    [check: @check_desc, params: [max_lines: @param_desc]]
  end

  def run(source_file, params) do
    cfg = make_config(source_file, params)
    prewalk(source_file, &check_module(&1, &2, cfg))
  end

  defp make_config(source_file, params) do
    %{max_lines: Keyword.get(params, :max_lines, 100),
      filename: source_file.filename,
      source: File.read!(source_file.filename)}
  end

  defp check_module({:defmodule, meta, [_ | _]} = ast, issues, cfg) do
    {ast, check_size(meta, issues, cfg)}
  end

  defp check_module(ast, issues, _cfg) do
    {ast, issues}
  end

  defp check_size(meta, issues, cfg) do
    meta
    |> find_body_lines(cfg.source)
    |> add_issue(cfg.max_lines, meta, issues, cfg.filename)
  end

  defp add_issue({:ok, lines}, max, meta, issues, filename)
       when lines > max do
    [create_issue(lines, max, meta, filename) | issues]
  end

  defp add_issue({:ok, _}, _, _, issues, _), do: issues
  defp add_issue(:error, _, _, issues, _), do: issues

  defp create_issue(body_lines, max_lines, meta, filename) do
    issue_for(__MODULE__, "Module", body_lines, max_lines, {meta, filename})
  end
end

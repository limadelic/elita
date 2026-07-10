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
    cfg = config(source_file, params)
    prewalk(source_file, &visit(&1, &2, cfg))
  end

  defp config(source_file, params) do
    %{max_lines: Keyword.get(params, :max_lines, 100),
      filename: source_file.filename,
      source: File.read!(source_file.filename)}
  end

  defp visit({:defmodule, meta, [_ | _]} = ast, issues, cfg) do
    {ast, measure(meta, issues, cfg)}
  end

  defp visit(ast, issues, _cfg) do
    {ast, issues}
  end

  defp measure(meta, issues, cfg) do
    meta
    |> lines(cfg.source)
    |> append(cfg.max_lines, meta, issues, cfg.filename)
  end

  defp append({:ok, lines}, max, meta, issues, filename)
       when lines > max do
    [item(lines, max, meta, filename) | issues]
  end

  defp append({:ok, _}, _, _, issues, _), do: issues
  defp append(:error, _, _, issues, _), do: issues

  defp item(body_lines, max_lines, meta, filename) do
    flag(__MODULE__, "Module", body_lines, max_lines, {meta, filename})
  end
end

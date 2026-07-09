defmodule Elita.Credo.Funclines do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code, only: [prewalk: 2]
  import Elita.Credo.Lines

  def param_defaults do
    [max_lines: 5]
  end

  @check_desc "Functions should be small and focused."
  @param_desc "The maximum number of lines a function body can have."

  def explanations do
    [check: @check_desc, params: [max_lines: @param_desc]]
  end

  def run(source_file, params) do
    cfg = make_config(source_file, params)
    prewalk(source_file, &check_function(&1, &2, cfg))
  end

  defp make_config(source_file, params) do
    %{max_lines: Keyword.get(params, :max_lines, 5),
      filename: source_file.filename,
      source: File.read!(source_file.filename)}
  end

  defp check_function({type, meta, [_head | _tail]} = ast, issues, cfg)
       when type in [:def, :defp, :defmacro] do
    {ast, process_function(ast, issues, meta, cfg)}
  end

  defp check_function(ast, issues, _cfg) do
    {ast, issues}
  end

  defp process_function(ast, issues, meta, cfg) do
    handle_body(is_receive_body?(ast), issues, meta, cfg)
  end

  defp handle_body(true, issues, _meta, _cfg), do: issues
  defp handle_body(false, issues, meta, cfg) do
    meta
    |> find_body_lines(cfg.source)
    |> add_issue(cfg.max_lines, meta, issues, cfg.filename)
  end

  defp is_receive_body?({_type, _meta, [_head | [[do: {:receive, _, _}]]]}), do: true
  defp is_receive_body?(_), do: false

  defp add_issue({:ok, lines}, max, meta, issues, filename)
       when lines > max do
    [create_issue(lines, max, meta, filename) | issues]
  end

  defp add_issue({:ok, _}, _, _, issues, _), do: issues
  defp add_issue(:error, _, _, issues, _), do: issues

  defp create_issue(body_lines, max_lines, meta, filename) do
    issue_for(__MODULE__, "Function", body_lines, max_lines, {meta, filename})
  end
end

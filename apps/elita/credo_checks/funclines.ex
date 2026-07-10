defmodule Elita.Credo.Funclines do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code, only: [prewalk: 2]
  import Elita.Credo.Lines
  import File, only: [read!: 1]

  def param_defaults do
    [max_lines: 5]
  end

  @check_desc "Functions should be small and focused."
  @param_desc "The maximum number of lines a function body can have."

  def explanations do
    [check: @check_desc, params: [max_lines: @param_desc]]
  end

  def run(file, params) do
    cfg = config(file, params)
    prewalk(file, &check(&1, &2, cfg))
  end

  defp config(file, params) do
    %{
      max_lines: Keyword.get(params, :max_lines, 5),
      filename: file.filename,
      source: read!(file.filename)
    }
  end

  defp check({type, meta, [_head | _tail]} = ast, issues, cfg)
       when type in [:def, :defp, :defmacro] do
    {ast, process(ast, issues, meta, cfg)}
  end

  defp check(ast, issues, _cfg) do
    {ast, issues}
  end

  defp process(ast, issues, meta, cfg) do
    handle(receive?(ast), issues, meta, cfg)
  end

  defp handle(true, issues, _meta, _cfg), do: issues

  defp handle(false, issues, meta, cfg) do
    meta
    |> lines(cfg.source)
    |> assess(cfg.max_lines, meta, issues, cfg.filename)
  end

  defp receive?({_type, _meta, [_head | [[do: {:receive, _, _}]]]}), do: true
  defp receive?(_), do: false

  defp assess({:ok, lines}, max, meta, issues, filename)
       when lines > max do
    [flag(__MODULE__, "Function", lines, max, {meta, filename}) | issues]
  end

  defp assess({:ok, _}, _, _, issues, _), do: issues
  defp assess(:error, _, _, issues, _), do: issues
end

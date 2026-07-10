defmodule Elita.Credo.Lines do
  @default_threshold 50
  @base_issue %Credo.Issue{category: :refactor, exit_status: 2}

  def lines(meta, source) do
    meta |> extract(source) |> result(meta)
  end

  defp result(nil, _meta), do: :error
  defp result(end_line, meta) when is_integer(end_line) do
    {:ok, end_line - Keyword.get(meta, :line, 0)}
  end
  defp result(_end_line, _meta), do: :error

  defp extract(meta, _source), do: line(Keyword.get(meta, :end))

  defp line(end_meta) when is_list(end_meta), do: Keyword.get(end_meta, :line)
  defp line(_), do: nil

  def flag(check, name, lines, max, {meta, filename}) do
    msg = "#{name} is too long (#{lines} lines, max is #{max})."
    pri = priority(lines - max)
    issue(check, msg, meta, pri, filename)
  end

  defp issue(check, msg, meta, pri, filename) do
    line = meta[:line]
    col = meta[:column]
    @base_issue |> merge({check, msg, line, col, pri, filename})
  end

  defp merge(issue, {c, m, l, col, p, f}) do
    issue |> Map.merge(%{check: c, message: m, line_no: l, column: col, priority: p, filename: f})
  end

  defp priority(severity)
       when severity > @default_threshold, do: :higher

  defp priority(_severity), do: :normal
end

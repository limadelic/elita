defmodule Elita.Credo.LineCheck do
  @default_threshold 50
  @base_issue %Credo.Issue{category: :refactor, exit_status: 2}

  def find_body_lines(meta) do
    meta |> extract_end_line() |> to_result(meta)
  end

  defp to_result(nil, _meta), do: :error
  defp to_result(end_line, meta), do: {:ok, count_lines(end_line, meta)}

  defp count_lines(end_line, meta) do
    end_line - Keyword.get(meta, :line, 0) - 1
  end

  defp extract_end_line(meta) do
    meta |> Keyword.get(:end_line) |> extract_end_line_impl(meta)
  end

  defp extract_end_line_impl(nil, meta), do: extract_from_expression(meta)
  defp extract_end_line_impl(end_line, _meta), do: end_line

  defp extract_from_expression(meta) do
    expr = Keyword.get(meta, :end_of_expression, [])
    Keyword.get(expr, :line)
  end

  def issue_for(check, name, lines, max, {meta, filename}) do
    msg = "#{name} is too long (#{lines} lines, max is #{max})."
    pri = calc_priority(lines - max)
    build_issue(check, msg, meta, pri, filename)
  end

  defp build_issue(check, msg, meta, pri, filename) do
    line = meta[:line]
    col = meta[:column]
    @base_issue |> update_issue_fields({check, msg, line, col, pri, filename})
  end

  defp update_issue_fields(issue, {c, m, l, col, p, f}) do
    issue |> Map.merge(%{check: c, message: m, line_no: l, column: col, priority: p, filename: f})
  end

  defp calc_priority(severity)
       when severity > @default_threshold, do: :higher

  defp calc_priority(_severity), do: :normal
end

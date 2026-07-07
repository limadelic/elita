defmodule Elita.Credo.LineCheck do
  @default_threshold 50
  @base_issue %Credo.Issue{category: :refactor, exit_status: 2}

  def find_body_lines(meta, source) do
    meta |> extract_end_line(source) |> to_result(meta)
  end

  defp to_result(nil, _meta), do: :error
  defp to_result(end_line, meta) when is_integer(end_line) do
    {:ok, end_line - Keyword.get(meta, :line, 0)}
  end
  defp to_result(_end_line, _meta), do: :error

  defp extract_end_line(meta, _source) do
    case Keyword.get(meta, :end) do
      end_meta when is_list(end_meta) -> Keyword.get(end_meta, :line)
      _ -> nil
    end
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

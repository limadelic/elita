#!/usr/bin/env elixir

System.put_env("MIX_ENV", "test")
File.cd!("/Users/mike/dev/self/elita-qa/apps/el")

:cover.start()

base_dir = "/Users/mike/dev/self/elita-qa"
["el", "elita"] |> Enum.each(fn app ->
  beam_dir = Path.join(base_dir, "_build/test/lib/#{app}/ebin")
  File.ls!(beam_dir) |> Enum.filter(&String.ends_with?(&1, ".beam")) |> Enum.each(fn beam ->
    :cover.compile_beam(Path.join(beam_dir, beam) |> to_charlist())
  end)
end)

File.cd!(base_dir)
:cover.import("coverdata.ets" |> to_charlist())

modules = :cover.imported_modules() |> Enum.sort()

IO.puts("\n=== COVERAGE SUMMARY ===")
IO.puts("Total modules: #{length(modules)}\n")

module_stats = modules
  |> Enum.map(fn mod ->
    result = try do :cover.analyse(mod) rescue _ -> nil end
    case result do
      {:ok, lines} ->
        covered = lines |> Enum.filter(fn {_, {c, _}} -> c > 0 end) |> length()
        total = length(lines)
        pct = if total > 0, do: Float.round(covered / total * 100, 2), else: 0.0
        {mod, pct, covered, total}
      _ -> nil
    end
  end)
  |> Enum.filter(& &1)
  |> Enum.sort_by(fn {_, p, _, _} -> p end, :desc)

module_stats |> Enum.each(fn {mod, pct, _, _} ->
  IO.puts("#{mod}: #{pct}%")
end)

total_pct = if length(module_stats) > 0 do
  sum = module_stats |> Enum.map(fn {_, p, _, _} -> p end) |> Enum.sum()
  (sum / length(module_stats)) |> Float.round(2)
else
  0.0
end

IO.puts("\n=== TOTAL COVERAGE: #{total_pct}% ===\n")

File.mkdir_p!("cover")
module_stats |> Enum.each(fn {mod, _, _, _} ->
  try do
    :cover.analyse_to_file(mod, Path.join("cover", "#{mod}.html") |> to_charlist(), [:html])
  rescue
    _ -> :ok
  end
end)

rows = module_stats |> Enum.map(fn {m, p, _, _} ->
  class = cond do p >= 80 -> "high"; p >= 50 -> "medium"; true -> "low" end
  "<tr class=\"#{class}\"><td>#{m}</td><td>#{p}%</td><td><a href=\"#{m}.html\">View</a></td></tr>"
end) |> Enum.join("\n")

index_html = """
<!DOCTYPE html>
<html><head><title>Coverage</title><style>
body{font-family:monospace;margin:20px}table{border-collapse:collapse;width:100%}
th,td{padding:8px;text-align:left;border-bottom:1px solid #ddd}th{background:#f2f2f2}
.high{background:#90EE90}.medium{background:#FFD700}.low{background:#FF6347}
</style></head><body><h1>Coverage Report</h1><p><strong>Total: #{total_pct}%</strong></p>
<table><tr><th>Module</th><th>%</th><th>Report</th></tr>
#{rows}
</table></body></html>
"""

File.write!("cover/index.html", index_html)
IO.puts("Reports: cover/index.html")

defmodule Mix.Tasks.Cover.Report do
  import File, only: [exists?: 1, read!: 1, write!: 2, mkdir_p!: 1]
  import IO, only: [puts: 1]
  import Enum, only: [map: 2, map_join: 3, reduce: 3, sum: 1]
  import Path, only: [expand: 1, join: 2]
  @compile {:no_warn_undefined, :cover}

  def run(_argv) do
    path = expand("coverdata.ets")
    handle_path(path, exists?(path))
  end

  defp handle_path(path, true) do
    process_coverage(path)
  end

  defp handle_path(_path, false) do
    puts("No coverdata.ets found. Run with COVER=1 to generate coverage data.")
  end

  defp process_coverage(path) do
    :cover.import(read!(path))
    generate_reports()
  end

  defp generate_reports do
    mkdir_p!("reports/coverage")
    write_reports(coverages(), "reports/coverage")
  end

  defp coverages do
    covered_modules() |> map(&module_coverage/1)
  end

  defp covered_modules do
    safe_modules(:cover.modules())
  end

  defp safe_modules(nil), do: []
  defp safe_modules(mods), do: mods

  defp module_coverage(module) do
    {module, coverage_percent(:cover.analyse(module, module))}
  end

  defp coverage_percent({:ok, analysis}), do: calc_coverage(analysis)
  defp coverage_percent(_error), do: 0

  defp calc_coverage(analysis) do
    {covered, uncovered} = count_coverage(analysis)
    pct(covered, covered + uncovered)
  end

  defp pct(_covered, 0), do: 0
  defp pct(covered, total), do: trunc(covered * 100 / total)

  defp count_coverage(analysis) do
    reduce(analysis, {0, 0}, &count_line/2)
  end

  defp count_line({_line, {:ok, _count}}, {c, u}), do: {c + 1, u}
  defp count_line({_line, {:not_covered, _count}}, {c, u}), do: {c, u + 1}
  defp count_line(_other, acc), do: acc

  defp write_reports(modules, report_dir) do
    cov = average(map(modules, &elem(&1, 1)))
    write_html(modules, report_dir)
    write_badge(cov, report_dir)
  end

  defp write_html(modules, report_dir) do
    write!(join(report_dir, "index.html"), index_html(modules))
  end

  defp write_badge(coverage, report_dir) do
    color = color_for(coverage)
    badge = ~s({"schemaVersion":1,"label":"coverage","message":"#{coverage}%","color":"#{color}"})
    write!(join(report_dir, "badge.json"), badge)
  end

  defp color_for(cov) when cov >= 80, do: "brightgreen"
  defp color_for(cov) when cov >= 60, do: "yellow"
  defp color_for(_cov), do: "red"

  defp index_html(modules) do
    rows = map_join(modules, "\n", &module_row/1)
    template(rows)
  end

  defp template(rows) do
    ~s(<html><head><title>Coverage</title><style>body{font-family:Arial}table{border-collapse:collapse}th,td{border:1px solid #ddd;padding:8px}</style></head><body><h1>Coverage Report</h1><table><tr><th>Module</th><th>%</th></tr>#{rows}</table></body></html>)
  end

  defp module_row({module, coverage}) do
    ~s(<tr><td>#{module}</td><td>#{coverage}%</td></tr>)
  end

  defp average([]), do: 0
  defp average(coverages), do: trunc(sum(coverages) / length(coverages))
end

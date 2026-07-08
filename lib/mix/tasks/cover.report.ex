defmodule Mix.Tasks.Cover.Report do
  def run(_argv) do
    coverdata_path = Path.expand("coverdata.ets")

    unless File.exists?(coverdata_path) do
      IO.puts("No coverdata.ets found. Run with COVER=1 to generate coverage data.")
      return
    end

    :cover.import(File.read!(coverdata_path))
    generate_reports()
  end

  defp generate_reports do
    modules = :cover.modules() || []
    report_dir = "reports/coverage"
    File.mkdir_p!(report_dir)

    modules
    |> Enum.map(&module_coverage/1)
    |> generate_index(report_dir)
  end

  defp module_coverage(module) do
    case :cover.analyse(module, module) do
      {:ok, analysis} -> {module, calc_coverage(analysis)}
      _error -> {module, 0}
    end
  end

  defp calc_coverage(analysis) do
    {covered, uncovered} =
      Enum.reduce(analysis, {0, 0}, fn
        {_line, {:ok, _count}}, {c, u} -> {c + 1, u}
        {_line, {:not_covered, _count}}, {c, u} -> {c, u + 1}
        _other, acc -> acc
      end)

    total = covered + uncovered
    if total == 0, do: 0, else: trunc(covered * 100 / total)
  end

  defp generate_index(modules, report_dir) do
    coverage = average(Enum.map(modules, &elem(&1, 1)))

    html = index_html(modules)
    File.write!(Path.join(report_dir, "index.html"), html)

    color = if coverage >= 80, do: "brightgreen", else: if coverage >= 60, do: "yellow", else: "red"
    badge = ~s({"schemaVersion":1,"label":"coverage","message":"#{coverage}%","color":"#{color}"})
    File.write!(Path.join(report_dir, "badge.json"), badge)

    IO.puts("Coverage report generated in #{report_dir}/")
    IO.puts("Total coverage: #{coverage}%")
  end

  defp index_html(modules) do
    rows =
      Enum.map_join(modules, "\n", fn {module, coverage} ->
        ~s(<tr><td>#{module}</td><td>#{coverage}%</td></tr>)
      end)

    ~s(<html><head><title>Coverage</title><style>body{font-family:Arial}table{border-collapse:collapse}th,td{border:1px solid #ddd;padding:8px}</style></head><body><h1>Coverage Report</h1><table><tr><th>Module</th><th>%</th></tr>#{rows}</table></body></html>)
  end

  defp average(coverages) do
    if Enum.empty?(coverages), do: 0, else: trunc(Enum.sum(coverages) / length(coverages))
  end
end

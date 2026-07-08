defmodule El.Cover do
  @compile {:no_warn_undefined, :cover}
  import Application, only: [ensure_all_started: 1]
  import File, only: [exists?: 1, ls!: 1, read!: 1, dir?: 1]
  import Path, only: [expand: 1, join: 2]
  import Enum, only: [filter: 2, each: 2]
  import String, only: [ends_with?: 2]
  import IO, only: [puts: 1]
  import Mix, only: [env: 0]
  import El.CLI, only: [main: 1]

  @moduledoc false

  @datafile "coverdata.ets"

  def run(argv) do
    ensure_all_started(:elita)
    start()
    call_cli(argv)
    export()
  end

  defp start do
    :cover.start()
    load()
    compile()
  end

  defp load do
    path = expand(@datafile)
    load_from(path, exists?(path))
  end

  defp load_from(_path, false), do: :ok
  defp load_from(path, true), do: :cover.import(read!(path))

  defp compile do
    beam_dirs() |> each(&load_dir/1)
  end

  defp beam_dirs do
    ["_build/#{env()}/lib/el/ebin", "_build/#{env()}/lib/elita/ebin"]
  end

  defp load_dir(dir) do
    full = expand(dir)
    load_if_dir(full, dir?(full))
  end

  defp load_if_dir(_full, false), do: :ok
  defp load_if_dir(full, true), do: load_beams(full)

  defp load_beams(dir) do
    beams(dir) |> each(&load_beam(dir, &1))
  end

  defp beams(dir) do
    dir |> ls!() |> filter(&is_beam/1)
  end

  defp is_beam(file) do
    ends_with?(file, ".beam")
  end

  defp load_beam(dir, file) do
    dir |> join(file) |> to_charlist() |> :cover.compile_beam()
  end

  defp call_cli(argv) do
    main(argv)
  end

  defp export do
    path = expand(@datafile) |> to_charlist()
    report_export(:cover.export(path))
  end

  defp report_export(:ok), do: :ok
  defp report_export({:ok, _data}), do: :ok
  defp report_export(error), do: puts("Warning: cover export returned #{inspect(error)}")
end

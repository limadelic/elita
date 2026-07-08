defmodule El.Cover do
  @compile {:no_warn_undefined, :cover}
  import Application, only: [ensure_all_started: 1]
  import File, only: [exists?: 1, ls!: 1, read!: 1, dir?: 1]
  import Path, only: [expand: 1, join: 2]
  import Enum, only: [filter: 2, each: 2]
  import String, except: [to_charlist: 1]
  import Mix, only: [env: 0]

  @moduledoc false

  @datafile "coverdata.ets"

  def run(argv) do
    ensure_all_started(:elita)
    start_coverage()
    El.CLI.main(argv)
    save_coverage()
  end

  defp start_coverage do
    :cover.start()
    load_previous_coverage()
    compile_all_beams()
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp load_previous_coverage do
    path = expand(@datafile)
    exists?(path) && :cover.import(read!(path))
  end

  defp compile_all_beams do
    beams() |> each(&compile_beam_dir/1)
  end

  defp beams do
    ["_build/#{env()}/lib/el/ebin", "_build/#{env()}/lib/elita/ebin"]
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp compile_beam_dir(path) do
    full = expand(path)
    dir?(full) && compile_beam_files(full)
  end

  defp compile_beam_files(dir) do
    dir |> ls!() |> filter(&beam_file?/1) |> each(&compile_beam(dir, &1))
  end

  defp beam_file?(file) do
    ends_with?(file, ".beam")
  end

  defp compile_beam(dir, beam) do
    :cover.compile_beam(dir |> join(beam) |> Kernel.to_charlist())
  end

  defp save_coverage do
    path = expand(@datafile) |> Kernel.to_charlist()
    case :cover.export(path) do
      :ok -> :ok
      {:ok, data} -> data
      error -> IO.puts("Warning: cover export returned #{inspect(error)}")
    end
  end
end

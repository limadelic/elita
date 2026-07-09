defmodule El.Cover do
  @compile {:no_warn_undefined, :cover}
  import Application, only: [ensure_all_started: 1]
  import File, only: [exists?: 1, ls!: 1, dir?: 1]
  import Path, only: [expand: 1, join: 2]
  import Enum, only: [filter: 2, each: 2]
  import String, only: [ends_with?: 2]
  import IO, only: [puts: 1]
  import System, only: [get_env: 1, delete_env: 1]
  import El.CLI, only: [main: 1]

  @moduledoc false
  @datafile "coverdata.ets"

  defp datafile_path, do: file_in_dir(get_env("COVER_DIR"), @datafile)

  defp file_in_dir(nil, file), do: Path.expand(file)
  defp file_in_dir(dir, file), do: Path.join(dir, file)

  def execute(argv) do
    setup()
    run_impl(argv)
  end

  defp setup do
    ensure_all_started(:elita)
    start()
    delete_env("COVER")
  end

  defp run_impl(argv) do
    main(argv)
    export()
  end

  def start do
    :cover.start()
    load()
    compile()
    System.at_exit(fn _code -> export() end)
  end

  defp compile do
    beam_dirs() |> each(&load_dir/1)
  end

  defp load do
    path = datafile_path()
    load_from(path, exists?(path))
  end

  defp load_from(_path, false), do: :ok
  defp load_from(path, true), do: :cover.import(path |> to_charlist())

  defp beam_dirs do
    base = File.cwd!() |> Path.dirname() |> Path.dirname()
    env = env_name()
    ["el", "elita"] |> Enum.map(&beam_dir(base, env, &1))
  end

  defp beam_dir(base, env, app) do
    Path.join(base, "_build/#{env}/lib/#{app}/ebin")
  end

  defp env_name, do: or_default(get_env("MIX_ENV"), "test")
  defp or_default(nil, default), do: default
  defp or_default(value, _), do: value

  defp load_dir(dir) do
    full = abs_path(dir)
    maybe_load_beams(full, dir?(full))
  end

  defp maybe_load_beams(_full, false), do: :ok
  defp maybe_load_beams(full, true), do: load_beams(full)

  defp abs_path("/" <> _ = path), do: path
  defp abs_path(path), do: expand(path)

  defp load_beams(dir) do
    beams(dir) |> each(&load_beam(dir, &1))
  end

  defp beams(dir) do
    dir |> ls!() |> filter(fn f -> ends_with?(f, ".beam") end)
  end

  defp load_beam(dir, file) do
    dir |> join(file) |> to_charlist() |> :cover.compile_beam()
  end

  def export do
    path = datafile_path() |> to_charlist()
    report_export(:cover.export(path))
  end

  defp report_export(:ok), do: :ok
  defp report_export({:ok, _data}), do: :ok
  defp report_export(error), do: puts("Warning: cover export returned #{inspect(error)}")
end

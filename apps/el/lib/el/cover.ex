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

  defp datafile_path do
    get_env("COVER_DIR") |> datafile_for_dir(@datafile)
  end

  defp datafile_for_dir(nil, file), do: Path.expand(file)
  defp datafile_for_dir(dir, file), do: Path.join(dir, file)

  def run(argv) do
    setup()
    execute(argv)
  end

  defp setup do
    ensure_all_started(:elita)
    start()
    delete_env("COVER")
  end

  defp execute(argv) do
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

  def export_unique(name) do
    path = expand(name) |> to_charlist()
    report_export(:cover.export(path))
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

  defp env_name, do: pick_env(get_env("MIX_ENV"))

  defp pick_env(nil), do: "test"
  defp pick_env(env), do: env

  defp load_dir(dir) do
    full = make_absolute(dir)
    load_beams_if(full, dir?(full))
  end

  defp make_absolute(path) do
    if String.starts_with?(path, "/"), do: path, else: expand(path)
  end

  defp load_beams_if(_full, false), do: :ok
  defp load_beams_if(full, true), do: load_beams(full)

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

  def export do
    path = datafile_path() |> to_charlist()
    report_export(:cover.export(path))
  end

  defp report_export(:ok), do: :ok
  defp report_export({:ok, _data}), do: :ok
  defp report_export(error), do: puts("Warning: cover export returned #{inspect(error)}")
end

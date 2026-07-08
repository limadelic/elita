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
    case get_env("COVER_DIR") do
      nil -> Path.expand(@datafile)
      dir -> Path.join(dir, @datafile)
    end
  end

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

    [
      Path.join(base, "_build/#{env}/lib/el/ebin"),
      Path.join(base, "_build/#{env}/lib/elita/ebin")
    ]
  end

  defp env_name, do: pick_env(get_env("MIX_ENV"))

  defp pick_env(nil), do: "test"
  defp pick_env(env), do: env

  defp load_dir(dir) do
    full = if String.starts_with?(dir, "/"), do: dir, else: expand(dir)
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

  def export do
    path = datafile_path() |> to_charlist()
    report_export(:cover.export(path))
  end

  defp report_export(:ok), do: :ok
  defp report_export({:ok, _data}), do: :ok
  defp report_export(error), do: puts("Warning: cover export returned #{inspect(error)}")
end

defmodule El.REPL do
  @compile {:no_warn_undefined, :cover}
  import Application, only: [ensure_all_started: 1]
  import Elita, only: [start_link: 2, call: 2]
  import IO, only: [read: 2, puts: 1, write: 1]
  import String, only: [trim: 1]
  import System, only: [get_env: 1, pid: 0]

  def run(agent) do
    ensure_all_started(:elita)
    setup_all(agent)
    loop(agent)
  end

  defp setup_all(agent) do
    Registry.start_link(keys: :unique, name: ElitaRegistry) |> settle()
    Tape.Writer.start_link(nil) |> settle()
    start_link(agent, [agent]) |> settle()
  end

  defp settle({:ok, _pid}), do: :ok
  defp settle({:error, {:already_started, _pid}}), do: :ok
  defp settle({:error, _}), do: :ok

  defp loop(agent) do
    show_prompt(agent)
    read(:stdio, :line) |> process(agent)
  end

  defp show_prompt(agent), do: write("#{agent}> ")

  defp process(:eof, _agent), do: :ok

  defp process(line, agent) do
    handle(agent, trim(line))
    export_if_covering()
    loop(agent)
  end

  defp export_if_covering, do: maybe_export(get_env("COVER"))

  defp maybe_export("1") do
    :cover.export(String.to_charlist(cover_file()))
  rescue
    _ -> :ok
  end

  defp maybe_export(_), do: :ok

  defp cover_file do
    dir = pick_dir(get_env("COVER_DIR"))
    "#{dir}coverdata.#{pid() |> to_string()}.ets"
  end

  defp pick_dir(nil), do: ""
  defp pick_dir(dir), do: dir

  defp handle(_agent, ""), do: :ok

  defp handle(agent, input) do
    call(agent, input) |> puts()
  end
end

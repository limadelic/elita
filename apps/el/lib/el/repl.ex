defmodule El.REPL do
  import Application, only: [ensure_all_started: 1]
  import Elita, only: [spawn: 2, request: 2]
  import IO, only: [read: 2, puts: 1, write: 1]
  import String, only: [trim: 1]
  import Registry, only: [start_link: 1]

  def run(agent) do
    ensure_all_started(:elita)
    setup_all(agent)
    loop(agent)
  end

  defp setup_all(agent) do
    start_link(keys: :unique, name: ElitaRegistry) |> settle()
    tape_start() |> settle()
    spawn(agent, [agent]) |> settle()
  end

  defp tape_start do
    Tape.Writer.start_link(nil)
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
    loop(agent)
  end

  defp handle(_agent, ""), do: :ok

  defp handle(agent, input) do
    request(agent, input) |> puts()
  end
end

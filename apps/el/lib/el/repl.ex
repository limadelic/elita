defmodule El.REPL do
  import Application, only: [ensure_all_started: 1]
  import Elita, only: [start_link: 2, call: 2]
  import IO, only: [read: 2, puts: 1, write: 1]
  import String, only: [trim: 1]

  def run(agent) do
    ensure_all_started(:elita)
    setup(agent)
    loop(agent)
  end

  defp setup(agent) do
    Registry.start_link(keys: :unique, name: ElitaRegistry) |> settle()
    Tape.Writer.start_link(nil) |> settle()
    start_link(agent, [agent]) |> settle()
  end

  defp settle({:ok, _pid}), do: :ok
  defp settle({:error, {:already_started, _pid}}), do: :ok
  defp settle({:error, _}), do: :ok

  defp loop(agent) do
    prompt(agent)
    read(:stdio, :line) |> process(agent)
  end

  defp prompt(agent), do: write("#{agent}> ")

  defp process(:eof, _agent), do: :ok

  defp process(line, agent) do
    handle(agent, trim(line)) |> proceed(agent)
  end

  defp proceed(:stop, _agent), do: :ok
  defp proceed(:ok, agent), do: loop(agent)

  defp handle(_agent, ""), do: :ok

  defp handle(_agent, "/exit"), do: :stop

  defp handle(agent, input) do
    call(agent, input) |> puts()
    :ok
  end
end

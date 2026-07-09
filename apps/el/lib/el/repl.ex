defmodule El.REPL do
  import Application, only: [ensure_all_started: 1]
  import Elita, only: [start_link: 2, call: 2]
  import IO, only: [read: 2, puts: 1, write: 1]
  import String, only: [trim: 1]
  import El.ShippedTape, only: [setup: 0]

  def run(agent) do
    ensure_all_started(:elita)
    setup_all(agent)
    loop(agent)
  end

  defp setup_all(agent) do
    setup()
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
    loop(agent)
  end

  defp handle(_agent, ""), do: :ok

  defp handle(agent, input) do
    call(agent, input) |> puts()
  end
end

defmodule Elita.Application do
  use Application

  import Agent.Manager, only: [launch: 0]
  import Elita, only: [prime: 0]
  import Mem, only: [setup: 0]
  import Registry, only: [child_spec: 1]
  import Supervisor, only: [start_link: 2]
  import System, only: [get_env: 1]

  def start(_type, _args) do
    setup()
    boot()
  end

  defp boot do
    {:ok, _} = run()
    launch()
    {:ok, _} = prime()
    {:ok, self()}
  end

  defp run do
    start_link(specs(), opts())
  end

  defp specs,
    do:
      [child_spec(keys: :unique, name: ElitaRegistry), spawner()] ++
        tapes()

  defp tapes,
    do: wrap(get_env("TAPE"))

  defp wrap(nil), do: []
  defp wrap(_), do: [tape()]

  defp tape,
    do: %{id: Tape.Writer, start: {Tape.Writer, :start_link, [nil]}}

  defp spawner,
    do: {DynamicSupervisor, name: Elita.Spawner, strategy: :one_for_one}

  defp opts,
    do: [strategy: :one_for_one, name: Elita.Supervisor]
end

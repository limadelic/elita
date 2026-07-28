defmodule Elita.Application do
  use Application

  import Agent.Manager, only: [launch: 0]
  import Application, only: [get_env: 2]
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
    {:ok, supervisor} = run()
    launch()
    {:ok, _} = prime()
    {:ok, supervisor}
  end

  defp run do
    start_link(specs(), opts())
  end

  defp specs,
    do:
      [child_spec(keys: :unique, name: ElitaRegistry), spawner(), tasks()] ++
        tapes() ++ mesh()

  defp tapes, do: t(get_env("TAPE"))
  defp t(nil), do: []
  defp t(_), do: [tape()]

  defp tape,
    do: %{id: Tape.Writer, start: {Tape.Writer, :start_link, [nil]}}

  defp mesh, do: m(get_env(:elita, :join_mesh))
  defp m(true), do: [s()]
  defp m(_), do: []

  defp s,
    do: %{id: Elita.Mesh, start: {Elita.Mesh, :start_link, [nil]}}

  defp spawner,
    do: {DynamicSupervisor, name: Elita.Spawner, strategy: :one_for_one}

  defp tasks,
    do: {Task.Supervisor, name: Elita.Tasks}

  defp opts,
    do: [strategy: :one_for_one, name: Elita.Supervisor]
end

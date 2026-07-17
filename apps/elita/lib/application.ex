defmodule Elita.Application do
  use Application

  import Agent.Manager, only: [launch: 0]
  import Elita, only: [prime: 0]
  import Mem, only: [setup: 0]
  import Registry, only: [child_spec: 1]
  import Supervisor, only: [start_link: 2]

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
    start_link([child_spec(keys: :unique, name: ElitaRegistry)], opts())
  end

  defp opts do
    [strategy: :one_for_one, name: Elita.Supervisor]
  end
end

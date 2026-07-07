defmodule Elita.Application do
  use Application

  import Agent.Manager, only: [start_agents: 0]
  import Mem, only: [init_global: 0]
  import Registry, only: [child_spec: 1]
  import Supervisor, only: [start_link: 2]

  def start(_type, _args) do
    init_global()
    boot()
  end

  defp boot do
    {:ok, _} = start_supervisor()
    start_agents()
    {:ok, _} = Elita.start_link("el", ["el"])
    {:ok, self()}
  end

  defp start_supervisor do
    start_link(
      [child_spec(keys: :unique, name: ElitaRegistry)],
      strategy: :one_for_one,
      name: Elita.Supervisor
    )
  end
end

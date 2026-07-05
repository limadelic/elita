defmodule Elita.Application do
  use Application
  import Mem, only: [init_global: 0]
  import Supervisor, only: [start_link: 2]
  import Agent.Registry, only: [create: 0]
  import Agent.Manager, only: [start_agents: 0]
  import Registry, only: [child_spec: 1]

  def start(_type, _args) do
    init_global()
    {:ok, _} = start_supervisor()
    create()
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

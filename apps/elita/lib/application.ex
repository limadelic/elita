defmodule Elita.Application do
  use Application
  import Mem, only: [init_global: 0]
  import Supervisor, only: [start_link: 2]

  def start(_type, _args) do
    init_global()
    start_supervisor()
    Agent.Registry.create()
    Agent.Manager.start_agents()
    {:ok, self()}
  end

  defp start_supervisor do
    start_link(
      [Registry.child_spec(keys: :unique, name: ElitaRegistry)],
      strategy: :one_for_one,
      name: Elita.Supervisor
    )
  end
end

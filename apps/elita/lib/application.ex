defmodule Elita.Application do
  use Application
  import Mem, only: [init_global: 0]

  def start(_type, _args) do
    init_global()
    {:ok, _} = Supervisor.start_link(children(), opts())
    Agent.Registry.create()
    Agent.Manager.start_agents()
    {:ok, self()}
  end

  defp children do
    [{Registry, keys: :unique, name: ElitaRegistry}]
  end

  defp opts do
    [strategy: :one_for_one, name: Elita.Supervisor]
  end
end

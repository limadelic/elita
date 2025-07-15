defmodule Elita.Manager do
  alias Elita.{Agent, Loader}
  import Loader, only: [agent: 1]

  def find_or_spawn(name) do
    with nil <- Registry.lookup(Elita.AgentRegistry, name) |> List.first() do
      agent_config = agent(name)
      {:ok, pid} = DynamicSupervisor.start_child(
        Elita.AgentSupervisor,
        {Agent, {name, agent_config}}
      )
      pid
    else
      {pid, _} -> pid
    end
  end
end
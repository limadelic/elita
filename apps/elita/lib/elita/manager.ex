defmodule Elita.Manager do
  alias Elita.{Agent, Loader}
  import Loader, only: [agent: 1]

  def ensure(name) do
    find(name) || spawn(name)
  end

  defp find(name) do
    case Registry.lookup(Elita.AgentRegistry, name) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  defp spawn(name) do
    {:ok, pid} = DynamicSupervisor.start_child(
      Elita.AgentSupervisor,
      {Agent, {name, agent(name)}}
    )
    pid
  end
end
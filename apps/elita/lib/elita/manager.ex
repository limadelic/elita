defmodule Elita.Manager do
  alias Elita.{Agent, Loader}
  import Loader, only: [agent: 1]

  def ensure(name) do
    case find(name) do
      nil -> spawn_group(name)
      pid -> pid
    end
  end

  defp find(name) do
    case Registry.lookup(Elita.AgentRegistry, name) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  defp spawn_group(name) do
    config = agent(name)
    main_pid = start(name, config)
    spawn_required(name, config.requires)
    main_pid
  end

  defp start(name, config) do
    {:ok, pid} = DynamicSupervisor.start_child(
      Elita.AgentSupervisor,
      {Agent, {name, config}}
    )
    pid
  end

  defp spawn_required(_name, requires) when map_size(requires) == 0, do: :ok
  defp spawn_required(name, requires) do
    Enum.each(requires, fn {role, template} ->
      agent_name = "#{name}_#{role}"
      config = agent(template)
      start(agent_name, config)
    end)
  end
end
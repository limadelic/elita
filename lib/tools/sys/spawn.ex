defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import Log, only: [log: 5]
  import Map, only: [get: 3]
  import Enum, only: [join: 2, random: 1, take_random: 2]
  import Cfgs, only: [value: 2]

  def def(name, state) do
    %{
      name: name,
      description: "Spawn a new agent.#{help(state)}",
      parameters: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Name for the new agent"},
          configs: %{
            type: "array",
            items: %{type: "string"},
            description: "Configs for the agent, defaults to [name]"
          }
        },
        required: ["name"]
      }
    }
  end

  def exec(_, %{"name" => name} = args, state) do
    configs = get(args, "configs", [name])
    log("🚀", name, "", "", :green)
    start_link(name, configs)
    {"spawned", state}
  end

  defp help(%{config: configs}) do
    agents = value(:agents, configs)
    """
    Available Agents: #{join(agents, ", ")}
    Examples:
    - spawn agent: spawn(name: "#{single(agents)}")
    - spawn named agent: spawn(name: "agent_name", configs: ["#{single(agents)}"])
    - spawn multi role agent: spawn(name: "hybrid", configs: ["#{join(many(agents), ", ")}"])
    """
  end

  defp single([]), do: "agent"
  defp single(agents), do: random(agents)
  
  defp many([]), do: ["agent1", "agent2"] 
  defp many([single]), do: [single]
  defp many(agents), do: take_random(agents, 2)
end

defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import Agent.Registry, only: [register: 3]
  import Log, only: [log: 5]
  import Map, only: [get: 2, get: 3]
  import Enum, only: [join: 2]
  alias Access

  def spec(name, state) do
    %{
      name: name,
      description: "Spawn a new agent.#{help(state)}",
      parameters: parameters()
    }
  end

  def exec(_, %{"name" => %{"name" => name} = inner}, state) do
    do_spawn(name, fetch_configs(get(inner, "configs"), name), state)
  end

  def exec(_, %{"name" => name} = args, state) do
    do_spawn(name, get(args, "configs", [name]), state)
  end

  def exec(_, %{"configs" => [name | _] = configs}, state) do
    do_spawn(name, configs, state)
  end

  defp help(_state) do
    "\nExamples:\n- spawn agent: spawn(name: \"my_agent\")\n- spawn named agent: spawn(name: \"agent_name\", configs: [\"config\"])\n- spawn multi role: spawn(name: \"hybrid\", configs: [\"config1\", \"config2\"])"
  end

  defp parameters do
    %{type: "object", properties: props(), required: ["name"]}
  end

  defp props do
    %{
      name: %{type: "string", description: "Name for the new agent"},
      configs: configs_prop()
    }
  end

  defp configs_prop do
    %{
      type: "array",
      items: %{type: "string"},
      description: "Configs for the agent, defaults to [name]"
    }
  end

  defp fetch_configs([_ | _] = list, _name) do
    list
  end

  defp fetch_configs(_other, name) do
    [name]
  end

  defp do_spawn(name, configs, state) do
    log(name, configs)
    {:ok, pid} = start_link(name, configs)
    register(to_atom(name), nil, pid)
    {"spawned", state}
  end

  defp to_atom(atom) when is_atom(atom), do: atom
  defp to_atom(string), do: String.to_atom(string)

  defp log(name, [name]) do
    log("🚀", name, "", "", :green)
  end

  defp log(name, config) do
    log("🚀", name, " as ", join(config, ", "), :green)
  end
end

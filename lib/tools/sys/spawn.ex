defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import Log, only: [log: 5]
  import Map, only: [get: 3]
  import Enum, only: [join: 2, random: 1, take_random: 2]
  import Cfgs, only: [value: 2]

  def def(name, state), do: spec(name, state)

  def exec(_, %{"name" => %{"name" => name} = inner}, state) do
    do_spawn(name, fetch_configs(inner["configs"], name), state)
  end

  def exec(_, %{"name" => name} = args, state) when is_binary(name) do
    do_spawn(name, get(args, "configs", [name]), state)
  end

  def exec(_, %{"configs" => [name | _] = configs}, state) do
    do_spawn(name, configs, state)
  end

  defp spec(name, state) do
    %{name: name, description: desc(state), parameters: parameters()}
  end

  defp desc(state) do
    "Spawn a new agent.#{help(state)}"
  end

  defp help(%{config: configs}) do
    agents = value(:agents, configs)
    help_text(agents)
  end

  defp help_text(agents) do
    body(agents)
  end

  defp body(agents) do
    "Available Agents: #{join(agents, ", ")}\nExamples:\n- spawn agent: spawn(name: \"#{single(agents)}\")\n- spawn named agent: spawn(name: \"agent_name\", configs: [\"#{single(agents)}\"])\n- spawn multi role agent: spawn(name: \"hybrid\", configs: [\"#{join(many(agents), ", ")}\"])"
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

  defp fetch_configs(list, _name) when is_list(list) do
    list
  end

  defp fetch_configs(_other, name) do
    [name]
  end

  defp do_spawn(name, configs, state) do
    log(name, configs)
    start_link(name, configs)
    {"spawned", state}
  end

  defp log(name, [name]) do
    log("🚀", name, "", "", :green)
  end

  defp log(name, config) do
    log("🚀", name, " as ", join(config, ", "), :green)
  end

  defp single([]), do: "agent"
  defp single(agents), do: random(agents)

  defp many([]), do: ["agent1", "agent2"]
  defp many([single]), do: [single]
  defp many(agents), do: take_random(agents, 2)
end

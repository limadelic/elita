defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import Log, only: [log: 5]
  import Map, only: [get: 3]
  import Enum, only: [join: 2]

  def def(name, _state) do
    %{
      name: name,
      description: "Spawn a new agent.\nExamples:\n- spawn agent: spawn(name: \"my_agent\")\n- spawn named agent: spawn(name: \"agent_name\", configs: [\"config\"])\n- spawn multi role: spawn(name: \"hybrid\", configs: [\"config1\", \"config2\"])",
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

  def exec(_, %{"name" => %{"name" => name} = inner}, state) do
    do_spawn(name, fetch_configs(inner["configs"], name), state)
  end

  def exec(_, %{"name" => name} = args, state) when is_binary(name) do
    do_spawn(name, get(args, "configs", [name]), state)
  end

  def exec(_, %{"configs" => [name | _] = configs}, state) do
    do_spawn(name, configs, state)
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
end

defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import Enum, only: [join: 2]
  import Log, only: [log: 5]
  import Map, only: [get: 2, get: 3]
  import Utils.World, only: [agents: 0]

  alias Access

  def spec(name, state) do
    %{name: name, description: description(state), parameters: parameters()}
  end

  defp description(state) do
    "Spawn an agent with the person's name and one or more configs. Configs must be existing agent files (boss, worker, actor, etc).#{help(state)}"
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
    available = agents() |> join(", ")

    "\nAvailable: #{available}\nExamples:\n- spawn agent: spawn(name: \"my_agent\")\n- spawn named agent: spawn(name: \"agent_name\", configs: [\"config\"])\n- spawn multi role: spawn(name: \"hybrid\", configs: [\"config1\", \"config2\"])"
  end

  defp parameters do
    %{type: "object", properties: props(), required: ["name"]}
  end

  defp props do
    %{
      name: %{type: "string", description: "Person's name, e.g. michael, dwight, pam, jim"},
      configs: configs()
    }
  end

  defp configs do
    %{type: "array", items: items(), description: blurb()}
  end

  defp items do
    %{type: "string", enum: agents()}
  end

  defp blurb do
    "Configs for the agent, defaults to [name]"
  end

  defp fetch_configs([_ | _] = list, _name) do
    list
  end

  defp fetch_configs(_other, name) do
    [name]
  end

  defp do_spawn(name, configs, state) do
    log(name, configs)
    started(start_link(name, configs), name)
    {"spawned", state}
  end

  defp started({:ok, _pid}, _name), do: :ok

  defp started({:error, {:already_started, _pid}}, _name) do
    :ok
  end

  defp log(name, [name]) do
    log("🚀", name, "", "", :green)
  end

  defp log(name, config) do
    log("🚀", name, " as ", join(config, ", "), :green)
  end
end

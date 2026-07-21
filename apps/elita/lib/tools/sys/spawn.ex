defmodule Tools.Sys.Spawn do
  import Elita, only: [spawn: 2]
  import Enum, only: [join: 2]
  import Log, only: [agent: 5]
  import Map, only: [get: 2, get: 3]
  import Utils.World, only: [agents: 0]

  @icon "🚀"

  def spec(name, state) do
    %{name: name, description: description(state), parameters: parameters()}
  end

  def icon, do: @icon

  defp description(state) do
    "Spawn an agent with the person's name and one or more configs. Configs must be existing agent files (boss, worker, actor, etc).#{help(state)}"
  end

  def exec(_, %{"name" => %{"name" => name} = inner}, state) do
    run(name, configs(get(inner, "configs"), name), state)
  end

  def exec(_, %{"name" => name} = args, state) do
    run(name, get(args, "configs", [name]), state)
  end

  def exec(_, %{"configs" => [name | _] = configs}, state) do
    run(name, configs, state)
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

  defp configs([_ | _] = list, _name) do
    list
  end

  defp configs(_other, name) do
    [name]
  end

  defp run(name, configs, %{name: spawner, skip_logs: silent} = state) do
    log(name, configs, spawner, silent)
    started(spawn(name, configs), name)
    {"spawned", state}
  end

  defp started({:ok, _pid}, _name), do: :ok

  defp log(_name, _config, _spawner, true) do
    :ok
  end

  defp log(_name, _config, "el", _) do
    :ok
  end

  defp log(name, [name], spawner, false) do
    agent(@icon, name, " | ", "spawn", %{name: spawner})
  end

  defp log(name, config, spawner, false) do
    agent(@icon, name, " as ", join(config, ", "), %{name: spawner})
  end
end

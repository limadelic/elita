defmodule Tools.Sys.Define do
  import Log, only: [log: 5]
  import Map, only: [get: 3]

  def def(name, _state) do
    %{
      name: name,
      description: "Define a new agent at runtime. Creates a markdown agent file that can then be spawned.",
      parameters: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Agent name (single word, lowercase)"},
          description: %{type: "string", description: "What this agent does"},
          tools: %{type: "string", description: "Comma separated tool names: set, get, tell, ask, spawn, define"},
          prompt: %{type: "string", description: "System prompt markdown for the agent"},
          ephemeral: %{type: "boolean", description: "If true, agent is destroyed when parent terminates. Default false (persists)."}
        },
        required: ["name", "prompt"]
      }
    }
  end

  def exec(_, args, state) do
    define(args, state)
  end

  defp define(%{"name" => name} = args, state) do
    insert(name, args, state)
  end

  defp insert(name, args, state) do
    :ets.delete(:elita_agents, name)
    md = build(name, args)
    :ets.insert(:elita_agents, {{:agent, name}, md})
    ephemeral? = get(args, "ephemeral", false)
    log("🧬", name, " defined ", "(#{count()} active)", :cyan)
    state = track(state, name, ephemeral?)
    {defined(name), state}
  end

  defp count do
    :ets.info(:elita_agents, :size)
  end

  defp build(name, args) do
    desc = get(args, "description", "")
    tools = get(args, "tools", "")
    prompt = get(args, "prompt", "")

    header(name, desc, tools) <> prompt
  end

  defp header(name, "", ""), do: "---\nname: #{name}\n---\n\n"
  defp header(name, desc, ""), do: "---\nname: #{name}\ndescription: #{desc}\n---\n\n"
  defp header(name, "", tools), do: "---\nname: #{name}\ntools: #{tools}\n---\n\n"
  defp header(name, desc, tools) do
    "---\nname: #{name}\ndescription: #{desc}\ntools: #{tools}\n---\n\n"
  end

  defp defined(name), do: "defined #{name}, ready to spawn"

  defp track(state, name, true = _ephemeral) do
    state
    |> track_defined(name)
    |> track_ephemeral(name)
  end

  defp track(state, name, _ephemeral) do
    track_defined(state, name)
  end

  defp track_defined(%{defined: list} = state, name), do: %{state | defined: list ++ [name]}
  defp track_defined(state, name), do: Map.put(state, :defined, [name])

  defp track_ephemeral(%{ephemeral: list} = state, name), do: %{state | ephemeral: list ++ [name]}
  defp track_ephemeral(state, name), do: Map.put(state, :ephemeral, [name])
end

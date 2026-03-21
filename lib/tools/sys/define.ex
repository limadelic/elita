defmodule Tools.Sys.Define do
  import Log, only: [log: 5]
  import Map, only: [get: 3]

  @limit 10

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
          prompt: %{type: "string", description: "System prompt markdown for the agent"}
        },
        required: ["name", "prompt"]
      }
    }
  end

  def exec(_, args, state) do
    count = count(state)
    define(args, state, count)
  end

  defp define(_, state, count) when count >= @limit do
    log("🚫", "define", ": ", "limit reached (#{@limit})", :red)
    {"error: agent limit reached", state}
  end

  defp define(%{"name" => name} = args, state, count) do
    md = build(name, args)
    :ets.insert(:elita_agents, {name, md})
    log("🧬", name, " defined ", "(#{count + 1}/#{@limit})", :cyan)
    state = track(state, name)
    {defined(name), state}
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

  defp track(%{defined: list} = state, name), do: %{state | defined: list ++ [name]}
  defp track(state, name), do: Map.put(state, :defined, [name])

  defp count(%{defined: list}), do: length(list)
  defp count(_), do: 0
end

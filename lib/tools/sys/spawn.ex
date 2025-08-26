defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import String, only: [downcase: 1, split: 2]
  import Log, only: [log: 5]
  import Map, only: [get: 2, get: 3]
  import Enum, only: [join: 2, find_value: 2, map: 2, reject: 2]

  def def(name, state) do
    %{
      name: name,
      description: "Spawn a new agent. #{examples(state)}#{agents(state)}",
      parameters: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Name for the new agent"},
          configs: %{type: "array", items: %{type: "string"}, description: "Configs for the agent, defaults to [name]"}
        },
        required: ["name"]
      }
    }
  end


  def exec(_, %{"name" => name} = args, state) do
    configs = get args, "configs", [name |> downcase]
    case configs do
      [^name] -> log("🚀", name, "", "", :green)
      _ -> log("🚀", name, " as ", join(configs, ", "), :green)
    end
    available = from(state)
    
    case check configs, available, name do
      :ok -> 
        start_link name |> downcase, configs
        {"spawned", state}
      {:error, msg} -> 
        {msg, state}
    end
  end

  defp check(_configs, [], _name), do: :ok
  defp check(configs, available, name) do
    invalid = reject configs, fn config -> config in available end
    case invalid do
      [] -> :ok
      _ -> 
        suggestions = map available, fn agent -> "spawn(name: \"#{name}\", configs: [\"#{agent}\"])" end
        {:error, "No '#{join invalid, ", "}' config available. Try: #{join suggestions, " or "}"}
    end
  end

  defp from(%{config: configs}) do
    case find_value configs, fn config -> get config, :agents end do
      nil -> []
      agents -> split agents, ", "
    end
  end
  defp from(_), do: []

  defp examples(%{config: configs}) do
    case find_value configs, fn config -> get config, :agents end do
      nil -> ""
      agents -> 
        agents = split agents, ", "
        examples = map agents, fn agent -> "spawn(name: \"my#{agent}\", configs: [\"#{agent}\"])" end
        "Examples: #{join examples, ", "}. "
    end
  end
  defp examples(_), do: ""

  defp agents(%{config: configs}) do
    configs
    |> find_value(fn config -> get config, :agents end)
    |> case do
      nil -> "No agents found in configs"
      agents -> "Available: #{agents}"
    end
  end
  defp agents(_), do: ""
end
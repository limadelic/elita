defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import String, only: [downcase: 1]
  import Log, only: [log: 5]

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

  def log({%{"args" => %{"name" => name} = args}, _state}) do
    configs = Map.get(args, "configs", [downcase(name)])
    case configs do
      [^name] -> log("🚀", name, "", "", :green)
      _ -> log("🚀", name, " as ", Enum.join(configs, ", "), :green)
    end
  end

  def log(response) do
    response
  end

  def exec(_, %{"name" => name} = args, state) do
    configs = Map.get(args, "configs", [name |> downcase()])
    available = get_available_agents(state)
    
    case validate_configs(configs, available, name) do
      :ok -> 
        start_link(name |> downcase(), configs)
        {"spawned", state}
      {:error, msg} -> 
        {msg, state}
    end
  end

  defp validate_configs(_configs, [], _name), do: :ok
  defp validate_configs(configs, available, name) do
    invalid = Enum.reject(configs, &(&1 in available))
    case invalid do
      [] -> :ok
      _ -> 
        suggestions = Enum.map(available, &"spawn(name: \"#{name}\", configs: [\"#{&1}\"])")
        {:error, "No '#{Enum.join(invalid, ", ")}' config available. Try: #{Enum.join(suggestions, " or ")}"}
    end
  end

  defp get_available_agents(%{config: configs}) do
    case Enum.find_value(configs, &Map.get(&1, :agents)) do
      nil -> []
      agents -> String.split(agents, ", ")
    end
  end
  defp get_available_agents(_), do: []

  defp examples(%{config: configs}) do
    case Enum.find_value(configs, &Map.get(&1, :agents)) do
      nil -> ""
      agents -> 
        agent_list = String.split(agents, ", ")
        examples = Enum.map(agent_list, &"spawn(name: \"my#{&1}\", configs: [\"#{&1}\"])")
        "Examples: #{Enum.join(examples, ", ")}. "
    end
  end
  defp examples(_), do: ""

  defp agents(%{config: configs}) do
    result = configs
    |> Enum.find_value(&Map.get(&1, :agents))
    |> case do
      nil -> "No agents found in configs"
      agents -> "Available: #{agents}"
    end
    result
  end
  defp agents(_), do: ""
end
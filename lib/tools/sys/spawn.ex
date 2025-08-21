defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import String, only: [downcase: 1]

  def def(name, state) do
    %{
      name: name,
      description: "Spawn a new agent. #{agents(state)}",
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
    configs = Map.get(args, "configs", [name |> downcase()])
    start_link(name |> downcase(), configs)
    {"spawned", state}
  end

  defp agents(%{config: configs}) do
    configs
    |> Enum.find_value(&Map.get(&1, :agents))
    |> case do
      nil -> ""
      agents -> "Available: #{agents}"
    end
  end
  defp agents(_), do: ""
end
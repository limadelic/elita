defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]
  import String, only: [downcase: 1]

  def def(name, _state) do
    %{
      name: name,
      description: "Spawn a new agent",
      parameters: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Name for the new agent"},
          configs: %{type: "string", description: "Configs for the agent, could be multiple, defaults to name"}
        },
        required: ["name"]
      }
    }
  end

  def exec(_, %{"name" => name} = args, _state) do
    configs = list(Map.get(args, "configs", name |> downcase()))
    start_link(name |> downcase(), configs)
    "spawned"
  end

  defp list(configs) when is_list(configs), do: configs
  defp list(config), do: [config]
end
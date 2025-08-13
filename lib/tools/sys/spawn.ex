defmodule Tools.Sys.Spawn do
  import Elita, only: [start_link: 2]

  def def(name) do
    %{
      name: name,
      description: "Spawn a new agent",
      parameters: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Name for the new agent"},
          mixins: %{type: "string", description: "Config mixins for the agent, defaults to name"}
        },
        required: ["name"]
      }
    }
  end

  def exec(_, %{"name" => agent_name} = args) do
    mixins = normalize_mixins(Map.get(args, "mixins", agent_name |> String.downcase()))
    name_atom = agent_name |> String.downcase() |> String.to_atom()
    start_link(mixins, name_atom)
    "spawned"
  end

  defp normalize_mixins(mixins) when is_list(mixins), do: mixins
  defp normalize_mixins(mixin), do: [String.to_atom(mixin)]
end
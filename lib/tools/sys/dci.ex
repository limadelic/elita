defmodule Tools.Sys.Dci do

  def def(name, state) do
    roles = state.config |> Enum.drop(1) |> Enum.map(& &1.name) |> Enum.join(", ")
    
    %{
      name: name,
      description: "Switch to role. Available: #{roles}",
      parameters: %{
        type: "object",
        properties: %{
          role: %{type: "string", description: "Role name to switch to"}
        },
        required: ["role"]
      }
    }
  end

  def exec(_, %{"role" => role}, state) do
    configs = Enum.map(state.config, &activate(&1, role))
    # TODO: figure out how to update state properly
    "switched to #{role}"
  end

  defp activate(config, target) do
    active = config.name == target
    Map.put(config, :active, active)
  end
end
defmodule Tools.Sys.Cast do
  import Log, only: [log: 5]
  import Map, only: [put: 3]
  import Enum, only: [drop: 2, map: 2, join: 2]

  def def(name, state) do
    %{
      name: name,
      description: "Switch to role. Available: #{roles(state.config)}. Use only once per turn.",
      parameters: %{
        type: "object",
        properties: %{
          role: %{type: "string", description: "Role name to switch to"}
        },
        required: ["role"]
      }
    }
  end

  def exec(_, %{"role" => role}, %{config: config, name: name} = state) do
    log("🎭", name, " as ", role, :magenta)
    {
      "switched to #{role}",
      %{state | config: map(config, &activate(&1, role))}
    }
  end

  defp roles(config) do
    config
    |> drop(1)
    |> map(& &1.name)
    |> join(", ")
  end

  defp activate(config, target) do
    put(config, :active, config.name == target)
  end
end

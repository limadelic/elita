defmodule Tools.Sys.Cast.Schema do
  import Enum, only: [drop: 2, map: 2, join: 2]

  def get(name, state) do
    %{name: name, description: desc(state), parameters: params()}
  end

  defp desc(state) do
    "Switch to role. Available: #{roles(state.config)}. Use only once per turn."
  end

  defp params do
    %{type: "object", properties: properties(), required: ["role"]}
  end

  defp properties do
    %{role: %{type: "string", description: "Role name to switch to"}}
  end

  defp roles(config) do
    config
    |> drop(1)
    |> map(& &1.name)
    |> join(", ")
  end
end

defmodule Tools.Sys.Cast do
  import Log, only: [log: 5]
  import Map, only: [put: 3]
  import Enum, only: [map: 2]

  defdelegate def(name, state), to: Tools.Sys.Cast.Schema, as: :get

  def exec(_, %{"role" => role}, %{config: config, name: name} = state) do
    log("🎭", name, " as ", role, :magenta)
    {
      "switched to #{role}",
      %{state | config: map(config, &activate(&1, role))}
    }
  end

  def exec(_, _args, state) do
    {"cast needs role", state}
  end

  defp activate(config, target) do
    put(config, :active, config.name == target)
  end
end

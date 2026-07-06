defmodule Tools.Sys.Become.Schema do
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

defmodule Tools.Sys.Become do
  import Log, only: [log: 5]
  import Map, only: [put: 3]
  import Enum, only: [map: 2]

  defdelegate spec(name, state), to: Tools.Sys.Become.Schema, as: :get

  def exec(_, %{"role" => role}, state) do
    log("🎭", state.name, " as ", role, :magenta)
    {"switched to #{role}", switch(state, role)}
  end

  def exec(_, _args, state) do
    {"become needs role", state}
  end

  defp switch(state, role) do
    %{state | config: map(state.config, &activate(&1, role))}
  end

  defp activate(config, target) do
    put(config, :active, config.name == target)
  end
end

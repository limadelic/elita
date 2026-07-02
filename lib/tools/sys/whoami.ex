defmodule Tools.Sys.Whoami do
  import Log, only: [log: 5]

  def def(name, _state), do: spec(name)

  def exec(_, _args, %{name: name} = state) do
    log("🤷", "I am ", name, "", :blue)
    {name, state}
  end

  defp spec(name) do
    %{name: name, description: "Get your own agent name", parameters: parameters()}
  end

  defp parameters do
    %{type: "object", properties: %{}, required: []}
  end
end

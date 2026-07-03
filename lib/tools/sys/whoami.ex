defmodule Tools.Sys.Whoami do
  import Log, only: [log: 5]

  defdelegate def(name, state), to: __MODULE__, as: :schema

  def schema(name, _state), do: build(name)

  defp build(name) do
    %{name: name, description: "Get your own agent name", parameters: params()}
  end

  def exec(_, _args, state) do
    announce(name(state), state)
  end

  defp announce(n, state) do
    log("🤷", "I am ", n, "", :blue)
    {n, state}
  end

  defp name(%{name: n}), do: n

  defp params do
    %{type: "object", properties: %{}, required: []}
  end
end

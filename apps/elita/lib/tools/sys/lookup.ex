defmodule Tools.Sys.Lookup.Schema do
  def get(name, _state) do
    %{name: name, description: "Query registry for agent location", parameters: params()}
  end

  defp params do
    %{type: "object", properties: properties(), required: ["name"]}
  end

  defp properties do
    %{
      name: %{type: "string", description: "Agent name to lookup"}
    }
  end
end

defmodule Tools.Sys.Lookup do
  import Agent.Registry, only: [lookup: 1]

  defdelegate spec(name, state), to: Tools.Sys.Lookup.Schema, as: :get

  def exec(_, %{"name" => name}, state) do
    {found(lookup(String.to_atom(name))), state}
  end

  def exec(_, _args, state) do
    {"lookup needs name", state}
  end

  defp found({:ok, {pid, folder}}), do: "#{inspect(pid)} at #{folder}"
  defp found({:error, :not_found}), do: "not found"
end

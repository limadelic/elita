defmodule Tools.Sys.Who.Schema do
  def get(name, _state) do
    %{name: name, description: description(), parameters: params()}
  end

  defp description do
    "List live agent sessions and available agent kinds"
  end

  defp params do
    %{type: "object", properties: %{}, required: []}
  end
end

defmodule Tools.Sys.Who do
  import Enum, only: [map: 2, join: 2]
  import Log, only: [log: 5]
  import Registry, only: [select: 2]
  import Utils.World, only: [agents: 0]

  @pattern [{{:"$1", :"$2", :"$3"}, [], [%{name: :"$1", kind: :"$3"}]}]

  defdelegate spec(name, state), to: Tools.Sys.Who.Schema, as: :get

  def exec(_, _args, state) do
    log("👥", "who", "", "", :green)
    {format_result(live_sessions(), agents()), state}
  end

  defp live_sessions do
    select(ElitaRegistry, @pattern) |> map(&format_session/1)
  end

  defp format_session(%{name: name, kind: %{kind: k}}) do
    "#{name} (#{k})"
  end

  defp format_session(%{name: name}), do: "#{name}"

  defp format_result([], kinds) do
    "live: none\navailable: #{join(kinds, ", ")}"
  end

  defp format_result(live, kinds) do
    "live: #{join(live, ", ")}\navailable: #{join(kinds, ", ")}"
  end
end

defmodule El.Commands.Lookup do
  import Elita, only: [call: 2]
  import String, only: [downcase: 1]

  def local(agent, msg, tool \\ nil, _opts \\ []) do
    normalized = downcase(agent)
    find(normalized, agent, msg, tool)
  end

  defp find(normalized, agent, msg, nil) do
    lookup(normalized) |> dispatch(agent, msg)
  end

  defp find(normalized, agent, msg, tool) do
    lookup("#{normalized}:#{tool}")
    |> fallback(normalized)
    |> dispatch(agent, msg)
  end

  defp lookup(key), do: Registry.lookup(ElitaRegistry, key)

  defp fallback([], fallback_key), do: lookup(fallback_key)
  defp fallback(result, _), do: result

  defp dispatch([], agent, _msg), do: IO.puts("unknown: #{agent}")
  defp dispatch([{_pid, _meta}], agent, msg), do: call(agent, msg) |> IO.puts()
end

defmodule El.Commands.Lookup do
  import Elita, only: [call: 2]
  import String, only: [downcase: 1]

  def local(agent, msg) do
    agent |> downcase |> find(agent, msg)
  end

  defp find(normalized, agent, msg) do
    Registry.lookup(ElitaRegistry, normalized) |> dispatch(agent, msg)
  end

  defp dispatch([], agent, _msg), do: IO.puts("unknown: #{agent}")
  defp dispatch([{_pid, _meta}], agent, msg), do: call(agent, msg) |> IO.puts()
end

defmodule El.Commands.Address.Send do
  import Enum, only: [each: 2]
  import GenServer, only: [cast: 2]
  import Registry, only: [lookup: 2]

  def tell(agent, msg, tool) do
    agent |> String.downcase() |> find(msg, tool)
  end

  defp find(n, msg, tool) do
    lookup(ElitaRegistry, key(n, tool))
    |> try_fallback(n)
    |> dispatch(msg)
  end

  defp key(n, nil), do: n
  defp key(n, tool), do: "#{n}:#{tool}"

  defp try_fallback([], n), do: lookup(ElitaRegistry, n)
  defp try_fallback(r, _), do: r

  defp dispatch([], _msg), do: :ok

  defp dispatch(pids, msg) do
    each(pids, fn {pid, meta} -> cast(pid, frame(meta[:kind], msg)) end)
  end

  defp frame(:native, msg), do: {:act, msg}
  defp frame(_, msg), do: {:cast, msg}
end

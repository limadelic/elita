defmodule El.Puppet.Burst do
  import Matrix.Log, only: [write: 1]
  import System, only: [monotonic_time: 1]

  def grow(state, data) do
    burst2 = count(state)
    log(state.burst, burst2)
    %{state | buffer: state.buffer <> data, last: monotonic_time(:millisecond), burst: burst2}
  end

  defp count(%{gap: true, burst: 1}), do: 2
  defp count(%{burst: b}), do: b

  defp log(b1, b2) when b2 > b1 do
    write("collect: burst transition #{b1} -> #{b2}\n")
  end

  defp log(_, _), do: :ok
end

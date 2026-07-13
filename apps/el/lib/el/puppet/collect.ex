defmodule El.Puppet.Collect do
  import El.Log, only: [write: 1]
  import El.Puppet.Settle, only: [hard: 2, peak: 3, solo: 3, ready: 2]
  import System, only: [monotonic_time: 1]
  import Exception, only: [format: 3]

  def collect(state) do
    safe(state)
  rescue e -> abort(e, __STACKTRACE__)
  catch k, r -> abort(k, r, __STACKTRACE__)
  end

  defp abort(e, stack) do
    write("collect exception: #{format(:error, e, stack)}\n")
    reraise e, stack
  end

  defp abort(k, r, stack) do
    write("collect caught: #{k} #{inspect(r)}\n")
    :erlang.raise(k, r, stack)
  end

  defp safe(%{last: last, start: start} = state) do
    now = monotonic_time(:millisecond)
    emit(state, now)
    defer(hard(state, now - start), state, now - last, now - start)
  end

  defp emit(%{buffer: buffer}, now) when byte_size(buffer) == 0 do
    write("collect entry on #{inspect(self())} at #{now}ms\n")
  end

  defp emit(_state, _now), do: :ok

  defp defer(false, state, quiet, elapsed) do
    go(state, quiet, elapsed)
  end

  defp defer(result, _state, _quiet, _elapsed) do
    result
  end

  defp go(state, quiet, elapsed) do
    gap = gap?(state, quiet)
    decide(%{state | gap: gap}, quiet, elapsed)
  end

  defp gap?(%{gap: true}, _quiet), do: true
  defp gap?(_state, quiet), do: quiet >= 2000

  defp decide(state, quiet, elapsed) when state.burst >= 2 do
    result = peak(state, quiet, elapsed)
    proceed(result, state, quiet)
  end

  defp decide(state, quiet, elapsed) when state.burst == 1 do
    result = solo(state, quiet, elapsed)
    proceed(result, state, quiet)
  end

  defp decide(state, quiet, _elapsed) do
    proceed(ready(state, quiet), state, quiet)
  end

  defp proceed(result, _state, _quiet) when result != false, do: result
  defp proceed(false, state, quiet), do: loop(state, quiet)

  defp loop(state, quiet) do
    receive do {:output, data} -> digest(state, data)
    after wait(state, quiet) -> collect(state) end
  end

  defp digest(state, data) do
    write("collect: burst #{state.burst} got #{byte_size(data)}b\n")
    collect(output(state, data))
  end

  defp wait(state, quiet) do
    elapsed = monotonic_time(:millisecond) - state.start
    min(4000 - quiet, 60_000 - elapsed) |> max(100)
  end

  defp output(state, data) do
    burst2 = surge(state)
    mark(state.burst, burst2)
    %{state | buffer: state.buffer <> data, last: monotonic_time(:millisecond), burst: burst2}
  end

  defp surge(%{gap: true, burst: 1}), do: 2
  defp surge(%{burst: b}), do: b

  defp mark(b1, b2) when b2 > b1, do: write("collect: burst transition #{b1} -> #{b2}\n")
  defp mark(_b1, _b2), do: :ok
end

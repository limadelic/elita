defmodule El.Puppet.Collect do
  import El.Log, only: [write: 1]
  import El.Pty, only: [unwatch: 2]
  import El.Puppet.Filter, only: [answer?: 2, mark: 1]
  import System, only: [monotonic_time: 1]
  import String, only: [contains?: 2]
  import Exception, only: [format: 3]

  def collect(state) do
    safe(state)
  rescue
    e ->
      write("collect exception: #{format(:error, e, __STACKTRACE__)}\n")
      reraise e, __STACKTRACE__
  catch
    kind, reason ->
      write("collect caught: #{kind} #{inspect(reason)}\n")
      :erlang.raise(kind, reason, __STACKTRACE__)
  end

  defp safe(state) do
    now = monotonic_time(:millisecond)
    quiet = now - state.last
    elapsed = now - state.start
    emit(state, now)
    defer(hard(state, elapsed), state, quiet, elapsed)
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

  defp hard(state, elapsed) when elapsed >= 60_000 do
    write("collect hard timeout at 60s\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  defp hard(_state, _elapsed), do: false

  defp go(state, quiet, elapsed) do
    gap = gap?(state, quiet)
    decide(%{state | gap: gap}, quiet, elapsed)
  end

  defp gap?(%{gap: true}, _quiet), do: true
  defp gap?(_state, quiet), do: quiet >= 2000

  defp decide(state, quiet, elapsed) when state.burst >= 2 do
    peak(state, quiet, elapsed)
  end

  defp decide(state, quiet, elapsed) when state.burst == 1 do
    solo(state, quiet, elapsed)
  end

  defp decide(state, quiet, _elapsed), do: ready(state, quiet)

  defp peak(state, quiet, elapsed) when quiet >= 1000 do
    write("collect: burst #{state.burst} settled after #{elapsed}ms\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  defp peak(state, quiet, _elapsed), do: ready(state, quiet)

  defp solo(%{gap: false} = state, quiet, elapsed) when quiet >= 500 do
    response(answer?(state.buffer, state.question), state, quiet, elapsed)
  end

  defp solo(state, quiet, _elapsed), do: ready(state, quiet)

  defp response(true, state, _quiet, elapsed) do
    write("collect: clean answer (burst 1) after #{elapsed}ms\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  defp response(false, state, quiet, _elapsed) do
    ready(state, quiet)
  end

  defp ready(state, quiet) do
    proceed(marker?(state, quiet), state, quiet)
  end

  defp marker?(%{buffer: buffer}, quiet) when quiet >= 1000 do
    contains?(buffer, "⏺")
  end

  defp marker?(_state, _quiet), do: false

  defp proceed(true, state, quiet) do
    write("collect: marker detected with #{quiet}ms quiet\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  defp proceed(false, state, quiet) do
    loop(state, quiet)
  end

  defp loop(state, quiet) do
    t = wait(state, quiet)

    receive do
      {:output, data} ->
        write("collect: burst #{state.burst} got #{byte_size(data)}b\n")
        collect(output(state, data))
    after
      t -> collect(state)
    end
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

  defp reply(buffer) do
    write("collect done bytes=#{byte_size(buffer)}\n")
    mark(buffer)
  end
end

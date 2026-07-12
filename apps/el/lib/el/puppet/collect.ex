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

    if byte_size(state.buffer) == 0,
      do: write("collect entry on #{inspect(self())} at #{now}ms\n")

    hard(state, elapsed) || go(state, quiet, elapsed)
  end

  defp hard(state, elapsed) when elapsed >= 60_000 do
    write("collect hard timeout at 60s\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  defp hard(_state, _elapsed), do: false

  defp go(state, quiet, elapsed) do
    gap = state.gap or quiet >= 2000
    decide(%{state | gap: gap}, quiet, elapsed)
  end

  defp decide(state, quiet, elapsed) when state.burst >= 2 and quiet >= 1000 do
    write("collect: burst #{state.burst} settled after #{elapsed}ms\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  defp decide(state, quiet, elapsed)
       when state.burst == 1 and not state.gap and quiet >= 500 do
    if answer?(state.buffer, state.question) do
      write("collect: clean answer (burst 1) after #{elapsed}ms\n")
      unwatch(state.pty, self())
      reply(state.buffer)
    else
      ready(state, quiet)
    end
  end

  defp decide(state, quiet, _elapsed), do: ready(state, quiet)

  defp ready(state, quiet) do
    if contains?(state.buffer, "⏺") and quiet >= 1000 do
      write("collect: marker detected with #{quiet}ms quiet\n")
      unwatch(state.pty, self())
      reply(state.buffer)
    else
      loop(state, quiet)
    end
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
    burst2 = if state.gap and state.burst == 1, do: 2, else: state.burst
    mark(state.burst, burst2)
    %{state | buffer: state.buffer <> data, last: monotonic_time(:millisecond), burst: burst2}
  end

  defp mark(b1, b2) when b2 > b1, do: write("collect: burst transition #{b1} -> #{b2}\n")
  defp mark(_b1, _b2), do: :ok

  defp reply(buffer) do
    write("collect done bytes=#{byte_size(buffer)}\n")
    mark(buffer)
  end
end

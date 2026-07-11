defmodule El.Puppet.Collect do
  import El.Log, only: [write: 1]
  import El.Pty, only: [unwatch: 2]
  import El.Puppet.Filter, only: [answer?: 2, polish: 1, final: 1]
  import System, only: [monotonic_time: 1]
  import String, only: [slice: 2]

  def collect(state) do
    now = monotonic_time(:millisecond)
    quiet = now - state.last
    elapsed = now - state.start

    if byte_size(state.buffer) == 0 do
      write("collect entry on #{inspect(self())} at #{now}ms\n")
    end

    if elapsed >= 60_000 do
      write("collect hard timeout at 60s\n")
      peek(state.buffer)
      unwatch(state.pty, self())
      reply(state.buffer)
    else
      gap = state.gap or quiet >= 2000
      if not state.gap and gap, do: peek(state.buffer)
      state = %{state | gap: gap}
      decide(state, quiet, elapsed)
    end
  rescue
    e ->
      write("collect exception: #{Exception.format(:error, e, __STACKTRACE__)}\n")
      reraise e, __STACKTRACE__
  catch
    kind, reason ->
      write("collect caught: #{kind} #{inspect(reason)}\n")
      :erlang.raise(kind, reason, __STACKTRACE__)
  end

  defp peek(buffer) do
    raw = buffer |> inspect(limit: :infinity) |> slice(0..599)
    p = buffer |> polish() |> inspect(limit: :infinity) |> slice(0..599)
    write("collect buffer raw: #{raw}\n")
    write("collect buffer polish: #{p}\n")
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
      loop(state, quiet)
    end
  end

  defp decide(state, quiet, _elapsed) when true do
    loop(state, quiet)
  end

  defp loop(state, quiet) do
    elapsed = monotonic_time(:millisecond) - state.start
    timeout = min(4000 - quiet, 60_000 - elapsed) |> max(100)

    receive do
      {:output, data} ->
        write("collect: burst #{state.burst} got #{byte_size(data)}b\n")
        now = monotonic_time(:millisecond)
        burst2 = if state.gap and state.burst == 1, do: 2, else: state.burst
        mark(state.burst, burst2)
        state2 = %{state | buffer: state.buffer <> data, last: now, burst: burst2}
        collect(state2)
    after
      timeout ->
        collect(state)
    end
  end

  defp mark(b1, b2) when b2 > b1 do
    write("collect: burst transition #{b1} -> #{b2}\n")
  end

  defp mark(_b1, _b2), do: :ok

  defp reply(buffer) do
    write("collect done bytes=#{byte_size(buffer)}\n")
    buffer |> polish() |> final()
  end
end

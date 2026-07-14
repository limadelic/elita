defmodule El.Puppet.Settle do
  import El.Log, only: [write: 1]
  import El.Pty, only: [unwatch: 2]
  import El.Puppet.Filter, only: [answer?: 2, mark: 1]
  import String, only: [contains?: 2]

  def hard(state, elapsed) when elapsed >= 60_000 do
    write("collect hard timeout at 60s\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  def hard(_state, _elapsed), do: false

  def peak(state, quiet, elapsed) when quiet >= 1000 do
    write("collect: burst #{state.burst} settled after #{elapsed}ms\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  def peak(state, quiet, _elapsed), do: ready(state, quiet)

  def solo(%{gap: false} = state, quiet, elapsed) do
    ans = answer?(state.buffer, state.question)
    response(ans, state, quiet, elapsed)
  end

  def solo(state, quiet, _elapsed), do: ready(state, quiet)

  defp response(true, state, _quiet, elapsed) do
    write("collect: clean answer (burst 1) after #{elapsed}ms\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  defp response(false, state, quiet, _elapsed) do
    ready(state, quiet)
  end

  def ready(state, quiet) do
    found = marker?(state, quiet)
    marked(found, state, quiet)
  end

  defp marked(true, state, quiet) do
    write("collect: marker detected with #{quiet}ms quiet\n")
    unwatch(state.pty, self())
    reply(state.buffer)
  end

  defp marked(false, _state, _quiet), do: false

  def marker?(%{buffer: buffer}, quiet) when quiet >= 1000 do
    contains?(buffer, "⏺")
  end

  def marker?(_state, _quiet), do: false

  defp reply(buffer) do
    write("collect done bytes=#{byte_size(buffer)}\n")
    mark(buffer)
  end
end

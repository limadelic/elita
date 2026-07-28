defmodule Matrix.Wrap.Resize do
  @moduledoc false
  import Process, only: [sleep: 1]

  def watch(pid, opts \\ []) do
    spawn(fn -> poll(pid, opts) end)
  end

  defp poll(pid, opts) do
    sleep(500)
    size = opts[:size]
    loop(pid, size, nil)
  end

  defp loop(pid, size, prev) do
    current = size.()
    changed(current, prev, pid)
    sleep(500)
    loop(pid, size, current)
  end

  defp changed(current, prev, pid) when current != prev do
    notify(current, pid)
  end

  defp changed(_current, _prev, _pid) do
    :ok
  end

  defp notify({rows, cols}, pid) do
    send(pid, {:resize, {rows, cols}})
  end

  defp notify(nil, _pid) do
    :ok
  end
end

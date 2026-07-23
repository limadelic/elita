defmodule Matrix.Wrap.Resize do
  @moduledoc false
  import Process, only: [sleep: 1]

  def watch(pid) do
    spawn(fn -> poll(pid) end)
  end

  defp poll(pid) do
    sleep(500)
    size = El.Commands.Size.size()
    notify(pid, size)
    poll(pid)
  end

  defp notify(pid, {rows, cols}) do
    send(pid, {:resize, {rows, cols}})
  end

  defp notify(_pid, nil) do
    :ok
  end
end

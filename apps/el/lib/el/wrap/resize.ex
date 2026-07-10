defmodule El.Wrap.Resize do
  @moduledoc false
  import El.Commands.Size, only: [size: 0]

  def watch(pid) do
    spawn(fn -> poll(pid) end)
  end

  defp poll(pid) do
    Process.sleep(500)
    new_size = size()
    notify(pid, new_size)
    poll(pid)
  end

  defp notify(pid, {rows, cols}) do
    send(pid, {:resize, {rows, cols}})
  end

  defp notify(_pid, nil) do
    :ok
  end
end

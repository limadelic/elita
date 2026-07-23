defmodule Matrix.Wrap.Resize do
  @moduledoc false
  import Process, only: [sleep: 1]

  def watch(pid, opts \\ []) do
    spawn(fn -> poll(pid, opts) end)
  end

  defp poll(pid, opts) do
    sleep(500)
    size = opts[:size]
    size.() |> notify(pid) |> then(fn _ -> poll(pid, opts) end)
  end

  defp notify(pid, {rows, cols}) do
    send(pid, {:resize, {rows, cols}})
  end

  defp notify(_pid, nil) do
    :ok
  end
end

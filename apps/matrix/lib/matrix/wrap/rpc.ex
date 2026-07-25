defmodule Matrix.Wrap.Rpc do
  import Matrix.Log, only: [write: 1]
  import Process, only: [monitor: 1]

  def call(pid, msg, opts \\ [])

  def call(pid, msg, opts) when node(pid) == node() do
    ask = opts[:ask]
    ask.(pid, msg)
  end

  def call(pid, msg, opts) do
    write("ask to #{node(pid)} from #{inspect(self())}\n")
    guard(pid, msg, opts)
  end

  defp guard(pid, msg, opts) do
    spawn(fn -> track(self()) end)
    attempt(pid, msg, opts)
  rescue
    _ -> :error
  end

  defp attempt(pid, msg, opts) do
    remote = node(pid)
    rpc(remote, pid, msg, opts)
  rescue
    _ -> :error
  end

  defp rpc(node, pid, msg, opts) do
    far = opts[:far]

    far.(node, pid, msg)
    |> tap(fn _ -> write("ask ok\n") end)
  end

  defp track(pid) do
    monitor(pid)
    await()
  end

  defp await do
    receive do
      {:DOWN, _, _, _, r} -> write("DOWN: #{inspect(r)}\n")
    end
  end
end

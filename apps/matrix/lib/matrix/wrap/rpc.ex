defmodule Matrix.Wrap.Rpc do
  import Process, only: [monitor: 1]
  import Task.Supervisor, only: [start_child: 2]

  def call(pid, msg, opts \\ [])

  def call(pid, msg, opts) when node(pid) == node() do
    ask = opts[:ask]
    ask.(pid, msg)
  end

  def call(pid, msg, opts) do
    guard(pid, msg, opts)
  end

  defp guard(pid, msg, opts) do
    watch(self())
    attempt(pid, msg, opts)
  catch
    :exit, _ -> :error
  end

  defp watch(caller) do
    start_child(Matrix.Tasks, fn -> track(caller) end)
  end

  defp attempt(pid, msg, opts) do
    remote = node(pid)
    rpc(remote, pid, msg, opts)
  catch
    :exit, _ -> :error
  end

  defp rpc(node, pid, msg, opts) do
    far = opts[:far]
    far.(node, pid, msg)
  end

  defp track(pid) do
    monitor(pid)
    await()
  end

  defp await do
    receive do
      {:DOWN, _, _, _, _r} -> :ok
    end
  end
end

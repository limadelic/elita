defmodule Matrix.Wrap.Rpc do
  import Matrix.Log, only: [write: 1]
  import Process, only: [monitor: 1]

  def call(pid, msg) when node(pid) == node(), do: El.Puppet.ask(pid, msg)

  def call(pid, msg) do
    write("ask to #{node(pid)} from #{inspect(self())}\n")
    guard(pid, msg)
  end

  defp guard(pid, msg) do
    spawn(fn -> track(self()) end)
    attempt(pid, msg)
  rescue
    _ -> :error
  end

  defp attempt(pid, msg) do
    pid
    |> node()
    |> then(fn n -> :erpc.call(n, El.Puppet, :ask, [pid, msg], 90_000) end)
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

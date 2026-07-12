defmodule El.Wrap.Rpc do
  import El.Log, only: [write: 1]
  import El.Puppet, only: [ask: 2]

  def call(pid, msg) when node(pid) == node(), do: ask(pid, msg)

  def call(pid, msg) do
    write("🤔 ask to #{node(pid)} from #{inspect(self())}\n")
    guard(pid, msg)
  end

  defp guard(pid, msg) do
    spawn(fn -> monitor(self()) end)
    attempt(pid, msg)
  rescue
    _ -> :error
  end

  defp attempt(pid, msg) do
    pid
    |> node()
    |> then(fn n -> :erpc.call(n, El.Puppet, :ask, [pid, msg], 90_000) end)
    |> tap(fn _ -> write("✨ ask ok\n") end)
  end

  defp monitor(pid) do
    Process.monitor(pid)
    await()
  end

  defp await do
    receive do
      {:DOWN, _, _, _, r} -> write("DOWN: #{inspect(r)}\n")
    end
  end
end

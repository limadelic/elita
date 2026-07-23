defmodule Matrix.Wrap.Rpc do
  import Matrix.Log, only: [write: 1]
  import Process, only: [monitor: 1]

  def call(pid, msg, opts \\ [])

  def call(pid, msg, opts) when node(pid) == node() do
    ask_fn = opts[:ask]
    ask_fn.(pid, msg)
  end

  def call(pid, msg, opts) do
    write("ask to #{node(pid)} from #{inspect(self())}\n")
    guard(pid, msg, opts)
  end

  defp guard(pid, msg, _opts) do
    spawn(fn -> track(self()) end)
    attempt(pid, msg)
  rescue
    _ -> :error
  end

  defp attempt(pid, msg, opts \\ []) do
    module = opts[:puppet_module] || ask_module()
    pid
    |> node()
    |> then(fn n -> :erpc.call(n, module, :ask, [pid, msg], 90_000) end)
    |> tap(fn _ -> write("ask ok\n") end)
  rescue
    _ -> :error
  end

  defp ask_module do
    # Construct module name dynamically to avoid static reference
    base = "El"
    name = "Puppet"
    String.to_atom("Elixir." <> base <> "." <> name)
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

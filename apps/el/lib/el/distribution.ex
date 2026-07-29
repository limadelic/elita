defmodule El.Distribution do
  import Application, only: [ensure_all_started: 1]
  import Process, only: [sleep: 1]
  import Node, only: [connect: 1, start: 2]
  import El.Boot, only: [go: 2]
  import El.Distribution.Helpers
  import El.Run, only: [address: 0, suffix: 0]
  import El.Trace, only: [write: 1]
  import String, only: [downcase: 1]
  import System, only: [cmd: 2]

  def start(name \\ :default), do: go(name, [])

  def bind(_name) do
    :ok
  end

  def target(name) do
    connect(:"#{name}#{suffix()}@127.0.0.1") |> route(name)
  end

  def wait(name) do
    norm = name |> to_string() |> downcase()
    flush()
    attach(name)
    open(norm)
  end

  defp flush do
    receive do
      {:puppet_ready, _, _} -> flush()
    after
      0 -> :ok
    end
  end

  defp open(norm) do
    branch(:global.register_name({:waiter, norm}, self()), norm)
  end

  defp branch(:yes, norm), do: ready(norm)

  defp branch(:no, norm) do
    flush()
    :global.whereis_name({norm, :puppet})
  end

  defp ready(norm) do
    check(norm, :global.whereis_name({norm, :puppet}))
  end

  defp check(norm, pid) when is_pid(pid) do
    done(norm, pid)
  end

  defp check(norm, :undefined) do
    await(norm)
  end

  defp await(norm) do
    receive do
      {:puppet_ready, ^norm, pid} ->
        done(norm, pid)
    after
      5_000 ->
        done(norm, nil)
    end
  end

  defp done(norm, value) do
    flush()
    :global.unregister_name({:waiter, norm})
    value
  end

  def launch do
    boot(address())
    ensure_all_started(:elita)
    sleep(:infinity)
  end

  defp boot(addr) do
    cmd("epmd", ["-daemon"])
    start(addr, :longnames)
  end

  def hidden(name) do
    node = :"#{name}@127.0.0.1"
    opts = %{name_domain: :longnames, hidden: true, dist_listen: false}
    :net_kernel.start(node, opts) |> outcome()
  end

  defp outcome({:ok, _}), do: :ok
  defp outcome({:error, {:already_started, _}}), do: :ok

  defp outcome({:error, reason}) do
    write("tunnel spawn failed reason=#{inspect(reason)}\n")
    :ok
  end
end

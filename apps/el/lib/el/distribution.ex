defmodule El.Distribution do
  import Application, only: [ensure_all_started: 1]
  import Process, only: [sleep: 1]
  import Node, only: [connect: 1, start: 2]
  import El.Boot, only: [go: 2]
  import El.Distribution.Helpers
  import El.Run, only: [address: 0, suffix: 0]
  import El.Trace, only: [write: 1]
  import String, only: [downcase: 1]

  def start(name \\ :default), do: run(name, [])

  defp run(name, opts), do: go(name, opts)

  def bind(_name) do
    :ok
  end

  def target(name) do
    connect(:"#{name}#{suffix()}@127.0.0.1") |> route(name)
  end

  def wait(name) do
    norm = normalize(name)
    attach(name)
    register(norm)
    ready(norm)
  end

  defp normalize(name) do
    name |> to_string() |> downcase()
  end

  defp register(norm) do
    :global.register_name({:waiter, norm}, self())
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
      {:puppet_ready, pid} ->
        done(norm, pid)
    after
      5_000 ->
        done(norm, nil)
    end
  end

  defp done(norm, value) do
    unregister(norm)
    value
  end

  defp unregister(norm) do
    :global.unregister_name({:waiter, norm})
  end

  def launch do
    boot(address())
    ensure_all_started(:elita)
    sleep(:infinity)
  end

  defp boot(addr) do
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

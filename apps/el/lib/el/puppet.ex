defmodule El.Puppet do
  use GenServer

  import Registry, only: [start_link: 1]
  import El.Pty, only: [watch: 2, unwatch: 2, inject: 2]
  import String, only: [ends_with?: 2]
  import Keyword, only: [fetch!: 2]

  def ask(pid, message) do
    GenServer.call(pid, {:ask, message}, :infinity)
  end

  def open(opts) do
    setup()
    name = fetch!(opts, :name)
    pty = fetch!(opts, :pty)
    register(name, pty)
  end

  defp register(name, pty) do
    via = {:via, Registry, {ElitaRegistry, name, %{kind: :puppet}}}
    {:ok, pid} = GenServer.start_link(__MODULE__, pty, name: via)
    notify(name, pid)
    {:ok, pid}
  end

  defp notify(name, pid) do
    alive?(Node.alive?(), name, pid)
  end

  defp alive?(true, name, pid) do
    :global.register_name({name, :puppet}, pid)
  end

  defp alive?(false, _name, _pid), do: :ok

  def init(pty) do
    {:ok, %{pty: pty}}
  end

  def handle_call({:ask, message}, _from, %{pty: pty} = state) do
    output = query(pty, message)
    {:reply, output, state}
  end

  defp query(pty, message) do
    watch(pty, self())
    inject(pty, message <> "\r")
    collect(pty, "")
  end

  defp collect(pty, buffer) do
    receive do
      {:output, data} ->
        ready(pty, buffer <> data, prompt?(buffer <> data))
    after
      5000 ->
        cleanup(pty)
        buffer
    end
  end

  defp ready(pty, buffer, true) do
    cleanup(pty)
    buffer
  end

  defp ready(pty, buffer, false) do
    collect(pty, buffer)
  end

  defp cleanup(pty) do
    unwatch(pty, self())
  rescue
    _ -> :ok
  end

  defp prompt?(text) do
    ends_with?(text, "> ")
  end

  defp setup do
    start_link(keys: :unique, name: ElitaRegistry)
  rescue
    _ -> :ok
  end
end

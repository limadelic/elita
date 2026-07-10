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
    pty = fetch!(opts, :pty_pid)
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

  def init(pty_pid) do
    {:ok, %{pty_pid: pty_pid}}
  end

  def handle_call({:ask, message}, _from, %{pty_pid: pty_pid} = state) do
    output = query(pty_pid, message)
    {:reply, output, state}
  end

  defp query(pty_pid, message) do
    watch(pty_pid, self())
    inject(pty_pid, message <> "\r")
    collect(pty_pid, "")
  end

  defp collect(pty_pid, buffer) do
    receive do
      {:output, data} ->
        ready(pty_pid, buffer <> data, prompt?(buffer <> data))
    after
      5000 ->
        cleanup(pty_pid)
        buffer
    end
  end

  defp ready(pty_pid, buffer, true) do
    cleanup(pty_pid)
    buffer
  end

  defp ready(pty_pid, buffer, false) do
    collect(pty_pid, buffer)
  end

  defp cleanup(pty_pid) do
    unwatch(pty_pid, self())
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

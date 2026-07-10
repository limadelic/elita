defmodule El.Puppet do
  use GenServer

  import GenServer, only: [start_link: 3, call: 3]
  import El.Pty, only: [watch: 2, unwatch: 2, inject: 2]
  import String, only: [ends_with?: 2]
  import Keyword, only: [fetch!: 2]
  import Process, only: [monitor: 1, demonitor: 1, whereis: 1]

  def ask(pid, message) do
    call(pid, {:ask, message}, :infinity)
  end

  def start_link(opts) do
    name = fetch!(opts, :name)
    pty = fetch!(opts, :pty_pid)
    register(name, pty)
  end

  defp register(name, pty) do
    via = {:via, Registry, {ElitaRegistry, name, %{kind: :puppet}}}
    {:ok, pid} = start_link(__MODULE__, pty, name: via)
    notify(name, pid)
    {:ok, pid}
  end

  defp notify(name, pid) do
    alive?(Node.alive?(), name, pid)
  end

  defp alive?(true, name, pid) do
    :global.register_name({name, :puppet}, pid)
  end

  defp alive?(false, _name, _pid) do
    :ok
  end

  def init(pty_pid) do
    {:ok, %{pty_pid: pty_pid}}
  end

  def handle_call({:ask, message}, _from, %{pty_pid: pty_pid} = state) do
    output = query(pty_pid, message)
    {:reply, output, state}
  end

  defp query(pty_pid, message) do
    watch(pty_pid, self())
    actual_pid = whereis_pid(pty_pid)
    monitor_ref = monitor(actual_pid)
    inject(pty_pid, message <> "\r")
    collect(pty_pid, "", monitor_ref)
  end

  defp whereis_pid(name) when is_atom(name), do: whereis(name) || name
  defp whereis_pid(pid), do: pid

  defp collect(pty_pid, buffer, monitor_ref) do
    receive do
      {:output, data} ->
        next = buffer <> data
        ready(pty_pid, next, prompt?(next), monitor_ref)
      {:DOWN, ^monitor_ref, :process, _pid, _} ->
        safe_unwatch(pty_pid)
        buffer
    after
      200 ->
        safe_unwatch(pty_pid)
        demonitor(monitor_ref)
        buffer
    end
  end

  defp ready(pty_pid, buffer, true, monitor_ref) do
    demonitor(monitor_ref)
    safe_unwatch(pty_pid)
    buffer
  end

  defp ready(pty_pid, buffer, false, monitor_ref) do
    collect(pty_pid, buffer, monitor_ref)
  end

  defp safe_unwatch(pty_pid) do
    unwatch(pty_pid, self())
  rescue
    _ -> :ok
  end

  defp prompt?(text) do
    ends_with?(text, "> ")
  end
end

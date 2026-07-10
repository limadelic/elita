defmodule El.Puppet do
  use GenServer

  import GenServer, only: [start_link: 3, call: 3]
  import El.Pty, only: [watch: 2, unwatch: 2, inject: 2]
  import String, only: [ends_with?: 2]
  import Keyword, only: [fetch!: 2]
  import El.Log, only: [write: 1]

  def ask(pid, message) do
    write("ask entry pid=#{inspect(pid)} message=#{inspect(message)}\n")
    result = call(pid, {:ask, message}, :infinity)
    write("ask exit pid=#{inspect(pid)} result_len=#{byte_size(result)}\n")
    result
  rescue
    e ->
      write("ask error: #{inspect(e)}\n")
      raise e
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
    write("puppet #{name} registered\n")
    {:ok, pid}
  rescue
    e ->
      write("puppet register error: #{inspect(e)}\n")
      reraise e, __STACKTRACE__
  end

  defp notify(name, pid) do
    alive?(Node.alive?(), name, pid)
  end

  defp alive?(true, name, pid) do
    result = :global.register_name({name, :puppet}, pid)
    write("global.register_name result: #{inspect(result)}\n")
    result
  end

  defp alive?(false, _name, _pid) do
    :ok
  end

  def init(pty_pid) do
    {:ok, %{pty_pid: pty_pid}}
  end

  def handle_call({:ask, message}, _from, %{pty_pid: pty_pid} = state) do
    write("handle_call ask message=#{inspect(message)}\n")
    output = query(pty_pid, message)
    write("handle_call ask done output_len=#{byte_size(output)}\n")
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
        next = buffer <> data
        ready(pty_pid, next, prompt?(next))
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
end

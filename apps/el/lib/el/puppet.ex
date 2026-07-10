defmodule El.Puppet do
  use GenServer

  import GenServer, only: [start_link: 3, call: 3]
  import El.Pty, only: [watch: 2, unwatch: 2, inject: 2]
  import String, only: [ends_with?: 2]
  import Keyword, only: [fetch!: 2]

  def ask(pid, message) do
    call(pid, {:ask, message}, :infinity)
  end

  def start_link(opts) do
    name = fetch!(opts, :name)
    pty = fetch!(opts, :pty_pid)
    register(name, pty)
  end

  defp register(name, pty) do
    import El.Log, only: [write: 1]
    via = {:via, Registry, {ElitaRegistry, name, %{kind: :puppet}}}
    {:ok, pid} = start_link(__MODULE__, pty, name: via)
    write("puppet #{name} registered pid=#{inspect(pid)}\n")
    notify(name, pid)
    {:ok, pid}
  end

  defp notify(name, pid) do
    alive?(Node.alive?(), name, pid)
  end

  defp alive?(true, name, pid) do
    import El.Log, only: [write: 1]
    result = :global.register_name({name, :puppet}, pid)

    write(
      "global register #{name}: #{inspect(result)} node=#{inspect(node())} alive=#{inspect(Node.alive?())}\n"
    )

    result
  end

  defp alive?(false, _name, _pid) do
    import El.Log, only: [write: 1]
    write("global register skipped: node not alive\n")
    :ok
  end

  def init(pty_pid) do
    {:ok, %{pty_pid: pty_pid}}
  end

  def handle_call({:ask, message}, _from, %{pty_pid: pty_pid} = state) do
    import El.Log, only: [write: 1]
    write("puppet ask #{inspect(message)}\n")
    output = query(pty_pid, message)
    {:reply, output, state}
  end

  defp query(pty_pid, message) do
    import El.Log, only: [write: 1]
    watch(pty_pid, self())
    inject(pty_pid, message <> "\r")
    write("puppet injected\n")
    collect(pty_pid, "")
  end

  defp collect(pty_pid, buffer) do
    import El.Log, only: [write: 1]

    receive do
      {:output, data} ->
        next = buffer <> data
        ready(pty_pid, next, prompt?(next))
    after
      5000 ->
        write("puppet collect timeout buffer=#{inspect(buffer)}\n")
        cleanup(pty_pid)
        buffer
    end
  end

  defp ready(pty_pid, buffer, true) do
    import El.Log, only: [write: 1]
    write("puppet prompt seen buffer=#{inspect(buffer)}\n")
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

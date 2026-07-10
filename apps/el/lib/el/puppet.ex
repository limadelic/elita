defmodule El.Puppet do
  use GenServer

  import GenServer, only: [start_link: 3, call: 3]
  import El.Pty, only: [untap: 2, inject: 2]
  import String, only: [ends_with?: 2]
  import Keyword, only: [fetch!: 2]

  def ask(pid, message) do
    call(pid, {:ask, message}, :infinity)
  end

  def start_link(opts) do
    name = fetch!(opts, :name)
    pty_pid = fetch!(opts, :pty_pid)
    via_tuple = {:via, Registry, {ElitaRegistry, name, %{kind: :puppet}}}
    start_link(__MODULE__, pty_pid, name: via_tuple)
  end

  def init(pty_pid) do
    {:ok, %{pty_pid: pty_pid}}
  end

  def handle_call({:ask, message}, _from, %{pty_pid: pty_pid} = state) do
    output = query(pty_pid, message)
    {:reply, output, state}
  end

  defp query(pty_pid, message) do
    El.Pty.tap(pty_pid, self())
    inject(pty_pid, message <> "\r")
    collect(pty_pid, "")
  end

  defp collect(pty_pid, buffer) do
    receive do
      {:output, data} ->
        next = buffer <> data
        ready(pty_pid, next, prompt?(next))
    end
  end

  defp ready(pty_pid, buffer, true) do
    untap(pty_pid, self())
    buffer
  end

  defp ready(pty_pid, buffer, false) do
    collect(pty_pid, buffer)
  end

  defp prompt?(text) do
    ends_with?(text, "> ")
  end
end

defmodule El.Puppet do
  use GenServer

  import Registry, only: [start_link: 1]
  import El.Pty, only: [inject: 2]
  import Keyword, only: [fetch!: 2]
  import El.Log, only: [write: 1]
  import El.Puppet.Invoke, only: [invoke: 2]
  import El.Puppet.Answer, only: [reply: 3]
  import El.Puppet.Parse, only: [envelope: 1]
  import GenServer, only: [call: 3, cast: 2, start_link: 3]

  def ask(pid, message) do
    call(pid, {:ask, message}, :infinity)
  end

  def put(pid, output) do
    cast(pid, {:put, output})
  end

  def open(opts) do
    setup()
    name = fetch!(opts, :name)
    pty = fetch!(opts, :pty)
    register(name, pty)
  end

  defp register(name, pty) do
    via = {:via, Registry, {ElitaRegistry, name, %{kind: :puppet}}}
    {:ok, pid} = start_link(__MODULE__, pty, name: via)
    notify(name, pid)
    {:ok, pid}
  end

  defp notify(_name, pid) do
    Process.register(pid, :puppet)
  end

  def init(pty) do
    {:ok, %{pty: pty}}
  end

  def handle_call({:ask, message}, _from, %{pty: pty} = state) do
    write("ask received: #{inspect(message)}\n")
    reply = invoke(pty, message)
    {:reply, reply, state}
  end

  def handle_cast({:put, output}, %{pty: pty} = state) do
    answer(output, pty, state)
  end

  defp answer(output, pty, state) do
    envelope(output) |> route(pty, output, state)
  end

  defp route({:ask, sender, message}, pty, _output, state) do
    spawn(fn -> reply(pty, sender, message) end)
    {:noreply, state}
  end

  defp route({:reply, _sender, message}, pty, _output, state) do
    inject(pty, message <> "\r")
    {:noreply, state}
  end

  defp route({:tell, _sender, _message}, pty, output, state) do
    inject(pty, output <> "\r")
    {:noreply, state}
  end

  defp route(:none, pty, output, state) do
    inject(pty, output <> "\r")
    {:noreply, state}
  end

  defp setup do
    start_link(keys: :unique, name: ElitaRegistry)
  rescue
    _ -> :ok
  end
end

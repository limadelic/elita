defmodule El.Puppet do
  use GenServer

  import Registry, only: [start_link: 1]
  import El.Pty, only: [inject: 2]
  import Keyword, only: [fetch!: 2]
  import El.Log, only: [write: 1]
  import String, only: [slice: 2]
  import Exception, only: [message: 1]
  import System, only: [get_env: 1]
  import Tape, only: [handle: 3]

  def ask(pid, message) do
    GenServer.call(pid, {:ask, message}, :infinity)
  end

  def put(pid, output) do
    GenServer.cast(pid, {:put, output})
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
    write("ask received: #{inspect(message)}\n")

    try do
      body = %{messages: [%{content: message}]}
      name = get_env("PUPPET_NAME") || "puppet"
      response = handle(body, name, fn ->
        output = El.Puppet.Query.call(pty, message)
        format(output)
      end)
      write("ask returned: #{inspect(slice(inspect(response), 0..50))}\n")
      {:reply, response, state}
    rescue
      e ->
        write("handle_call exception: #{message(e)}\n")
        {:reply, {:error, e}, state}
    catch
      kind, reason ->
        write("handle_call caught: #{kind} #{inspect(reason)}\n")
        {:reply, {:error, {kind, reason}}, state}
    end
  end

  defp format(text) when is_binary(text) do
    [%{"text" => text, "type" => "text"}]
  end

  defp format(response), do: response

  def handle_cast({:put, output}, %{pty: pty} = state) do
    inject(pty, output <> "\r")
    {:noreply, state}
  end

  defp setup do
    start_link(keys: :unique, name: ElitaRegistry)
  rescue
    _ -> :ok
  end
end

defmodule El.Puppet do
  use GenServer

  import Registry, only: [start_link: 1]
  import El.Pty, only: [inject: 2]
  import Keyword, only: [fetch!: 2]
  import El.Log, only: [write: 1]
  import String, only: [slice: 2]
  import Exception, only: [message: 1]
  import System, only: [get_env: 1]
  import Tape.Store, only: [add: 2]

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
    spread(name, pid)
    {:ok, pid}
  end

  defp spread(name, pid) do
    share(Node.alive?(), name, pid)
  end

  defp share(true, name, pid) do
    :global.register_name({name, :puppet}, pid)
  end

  defp share(false, _name, _pid), do: :ok

  def init(pty) do
    {:ok, %{pty: pty}}
  end

  def handle_call({:ask, message}, _from, %{pty: pty} = state) do
    write("ask received: #{inspect(message)}\n")

    case process(pty, message) do
      {:ok, response} -> {:reply, response, state}
      {:error, e} -> {:reply, {:error, e}, state}
    end
  end

  defp process(pty, message) do
    try do
      response = query(pty, message)
      record(message, response)
      {:ok, response}
    rescue
      e ->
        mark(:rescue, e)
    catch
      kind, reason ->
        mark(:catch, {kind, reason})
    end
  end

  defp query(pty, message) do
    output = El.Puppet.Query.call(pty, message)
    response = format(output)
    write("ask returned: #{inspect(slice(inspect(response), 0..50))}\n")
    response
  end

  defp mark(:rescue, e) do
    write("handle_call exception: #{message(e)}\n")
    {:error, e}
  end

  defp mark(:catch, {kind, reason}) do
    write("handle_call caught: #{kind} #{inspect(reason)}\n")
    {:error, {kind, reason}}
  end

  defp format(text) when is_binary(text) do
    [%{"text" => text, "type" => "text"}]
  end

  defp format(response), do: response

  defp record(message, response) do
    save(get_env("TAPE") == "rec", message, response)
  end

  defp save(true, message, response) do
    try do
      name = get_env("PUPPET_NAME") || "puppet"
      request = build(name, message)
      add(request, response)
    catch
      _, _ -> write("record fail\n")
    end
  end

  defp save(false, _message, _response), do: :ok

  defp build(name, message) do
    %{"agent" => name, "messages" => [%{content: message}], "n" => 1}
  end

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

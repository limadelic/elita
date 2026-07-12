defmodule El.Puppet do
  use GenServer

  import Registry, only: [start_link: 1]
  import El.Pty, only: [inject: 2]
  import Keyword, only: [fetch!: 2]
  import El.Log, only: [write: 1]
  import String, only: [slice: 2]
  import System, only: [get_env: 1]
  import Tape.Store, only: [add: 2]
  import El.Puppet.Query, only: [call: 2]

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
    reply = invoke(pty, message)
    {:reply, reply, state}
  end

  defp invoke(pty, message) do
    try do: respond(pty, message),
        rescue: (e -> error("exception", e)),
        catch: (k, r -> error("caught", {k, r}))
  end

  defp respond(pty, message) do
    response = format(call(pty, message))
    log(response)
    record(message, response)
    response
  end

  defp log(response) do
    write("ask returned: #{inspect(slice(inspect(response), 0..50))}\n")
  end

  defp error(kind, reason) do
    write("handle_call #{kind}: #{inspect(reason)}\n")
    {:error, reason}
  end

  defp format(text) when is_binary(text) do
    [%{"text" => text, "type" => "text"}]
  end

  defp format(response), do: response

  defp record(message, response) do
    recording?() && save(message, response)
  end

  defp recording? do
    get_env("TAPE") == "rec"
  end

  defp save(message, response) do
    try do: add(build(message), response), catch: (_, _ -> fail())
  end

  defp build(message) do
    %{"agent" => agent(), "messages" => [%{content: message}], "n" => 1}
  end

  defp agent do
    get_env("PUPPET_NAME") || "puppet"
  end

  defp fail do
    write("record fail\n")
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

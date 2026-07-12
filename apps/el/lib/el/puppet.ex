defmodule El.Puppet do
  use GenServer

  import Registry, only: [start_link: 1]
  import El.Pty, only: [inject: 2, watch: 2, unwatch: 2]
  import Keyword, only: [fetch!: 2]
  import El.Log, only: [write: 1]
  import El.Puppet.Invoke, only: [invoke: 2]
  import El.Puppet.Collect, only: [collect: 1]
  import System, only: [monotonic_time: 1]
  import String, only: [to_atom: 1, trim: 1]

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


  def handle_cast({:put, output}, %{pty: pty} = state) do
    answer(output, pty, state)
  end

  defp answer(output, pty, state) do
    case parse(output) do
      {:ask, sender, message} ->
        spawn(fn -> reply(pty, sender, message) end)
        {:noreply, state}
      {:reply, _sender, message} ->
        inject(pty, message <> "\r")
        {:noreply, state}
      {:tell, _sender, _message} ->
        inject(pty, output <> "\r")
        {:noreply, state}
      :none ->
        inject(pty, output <> "\r")
        {:noreply, state}
    end
  end

  defp parse(text) do
    case String.split(text, "\n", parts: 2) do
      ["[ask " <> rest, message] ->
        case String.split(rest, "]", parts: 2) do
          [sender, ""] -> {:ask, to_atom(sender), message}
          _ -> :none
        end
      ["[reply " <> rest, message] ->
        case String.split(rest, "]", parts: 2) do
          [sender, ""] -> {:reply, to_atom(sender), message}
          _ -> :none
        end
      ["[from " <> rest, message] ->
        case String.split(rest, "]", parts: 2) do
          [sender, ""] -> {:tell, to_atom(sender), message}
          _ -> :none
        end
      _ ->
        :none
    end
  end

  defp reply(pty, sender, message) do
    watch(pty, self())
    inject(pty, message <> "\r")
    response = collect(build(pty, message, monotonic_time(:millisecond)))
    unwatch(pty, self())
    write("ask reply collected: #{inspect(String.slice(inspect(response), 0..50))}\n")
    signal(sender, format(response))
  catch
    :exit, _ -> write("reply exit\n")
  end

  defp format(response) when is_list(response) do
    case response do
      [%{"text" => text} | _] -> text
      _ -> inspect(response)
    end
  end

  defp format(response) when is_binary(response), do: response
  defp format(response), do: inspect(response)

  defp signal(sender, response) do
    name = trim(to_string(sender))
    envelope = "[reply #{name}]"
    text = "#{envelope}\n#{response}"
    write("ask reply to: #{inspect(sender)} text: #{inspect(text)}\n")
    direct(sender, text)
  end

  defp direct(target, text) do
    case target(target) do
      nil ->
        write("direct nil: cannot deliver\n")
        :ok
      pid ->
        put(pid, text)
    end
  end

  defp target(name) when is_atom(name) do
    case :global.whereis_name({name, :puppet}) do
      :undefined -> nil
      pid -> pid
    end
  rescue
    _ -> nil
  end

  defp build(pty, message, now) do
    %{pty: pty, buffer: "", last: now, start: now,
      question: message, burst: 1, gap: false}
  end

  defp setup do
    start_link(keys: :unique, name: ElitaRegistry)
  rescue
    _ -> :ok
  end
end

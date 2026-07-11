defmodule El.Puppet do
  use GenServer

  import Registry, only: [start_link: 1]
  import El.Pty, only: [watch: 2, unwatch: 2, inject: 2]
  import Keyword, only: [fetch!: 2]
  import String, only: [replace: 3, trim: 1]
  import El.Log, only: [write: 1]

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
    output = query(pty, message)
    write("ask returned: #{inspect(String.slice(output, 0..50))}\n")
    {:reply, output, state}
  end

  def handle_cast({:put, output}, %{pty: pty} = state) do
    inject(pty, output <> "\r")
    {:noreply, state}
  end

  defp query(pty, message) do
    write("inject to pty: #{inspect(message)}\n")
    watch(pty, self())
    inject(pty, message <> "\r")
    collect(pty, "", 0, 0)
  end

  defp collect(pty, buffer, quiet, elapsed) do
    receive do
      {:output, data} ->
        collect(pty, buffer <> data, 0, elapsed)
    after
      500 ->
        elapsed = elapsed + 500
        done?(pty, buffer, quiet, elapsed) || collect(pty, buffer, quiet + 500, elapsed)
    end
  end

  defp done?(pty, buffer, quiet, elapsed) do
    case {quiet >= 4000 && trim(buffer) != "", elapsed >= 60_000} do
      {true, _} ->
        cleanup(pty)
        reply(buffer)

      {false, true} ->
        write("collect hard timeout at 60s\n")
        cleanup(pty)
        reply(buffer)

      {false, false} ->
        nil
    end
  end

  defp reply(buffer) do
    stripped = clean(buffer)

    trimmed =
      stripped
      |> replace(~r/Type \? for shortcuts[^\n]*/i, "")
      |> replace(~r/Press [Ctrl\+C]+ to exit[^\n]*/i, "")
      |> replace(~r/\(type .+ for help\)[^\n]*/i, "")
      |> replace(~r/[┌┐└┘─│├┤┬┴┼]/, "")
      |> replace(~r/\s+/, " ")
      |> trim()

    if String.length(trimmed) > 20, do: trimmed, else: stripped
  end

  defp cleanup(pty) do
    unwatch(pty, self())
  rescue
    _ -> :ok
  end

  defp clean(text),
    do: String.replace(text, ~r/\e\[[0-9;?]*[a-zA-Z]|\e[78]|\e\][^\a]*\a/, "")

  defp setup do
    start_link(keys: :unique, name: ElitaRegistry)
  rescue
    _ -> :ok
  end
end

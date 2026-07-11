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

    try do
      output = query(pty, message)
      write("ask returned: #{inspect(String.slice(output, 0..50))}\n")
      {:reply, output, state}
    rescue
      e ->
        write("handle_call exception: #{Exception.message(e)}\n")
        {:reply, {:error, e}, state}
    catch
      kind, reason ->
        write("handle_call caught: #{kind} #{inspect(reason)}\n")
        {:reply, {:error, {kind, reason}}, state}
    end
  end

  def handle_cast({:put, output}, %{pty: pty} = state) do
    inject(pty, output <> "\r")
    {:noreply, state}
  end

  defp query(pty, message) do
    write("query on #{inspect(self())} (node #{inspect(node())})\n")
    write("inject to pty: #{inspect(message)}\n")

    try do
      watch(pty, self())
      write("watched pty, caller self() = #{inspect(self())}\n")
      inject(pty, message <> "\r")
      now = System.monotonic_time(:millisecond)
      collect(pty, "", now, now, message)
    rescue
      e ->
        write("query exception: #{Exception.message(e)}\n")
        reraise e, __STACKTRACE__
    catch
      kind, reason ->
        write("query caught: #{kind} #{inspect(reason)}\n")
        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  defp collect(pty, buffer, last, start, question) do
    try do
      now = System.monotonic_time(:millisecond)
      quiet = now - last
      elapsed = now - start

      if byte_size(buffer) == 0 do
        write("collect entry on #{inspect(self())} (node #{inspect(node())}) at #{now}ms\n")
      end

      cond do
        quiet >= 4000 && answer?(buffer, question) ->
          write("collect: quiesce after #{elapsed}ms\n")
          cleanup(pty)
          reply(buffer)

        elapsed >= 60_000 ->
          write("collect hard timeout at 60s (elapsed=#{elapsed}ms)\n")
          cleanup(pty)
          reply(buffer)

        true ->
          timeout = min(4000 - quiet, 60_000 - elapsed) |> max(0)
          write("collect: waiting #{timeout}ms (quiet=#{quiet}, elapsed=#{elapsed})\n")

          receive do
            {:output, data} ->
              write(
                "collect got #{byte_size(data)}b data at #{System.monotonic_time(:millisecond)}ms\n"
              )

              collect(pty, buffer <> data, now, start, question)
          after
            timeout ->
              tick(elapsed, quiet, buffer)
              collect(pty, buffer, last, start, question)
          end
      end
    rescue
      e ->
        write("collect exception: #{Exception.format(:error, e, __STACKTRACE__)}\n")
        reraise e, __STACKTRACE__
    catch
      kind, reason ->
        write("collect caught: #{kind} #{inspect(reason)}\n")
        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  defp tick(elapsed, quiet, buffer) when rem(div(elapsed, 1000), 10) == 0 and quiet >= 1000 do
    write("collect tick quiet=#{quiet} elapsed=#{elapsed} bytes=#{byte_size(buffer)}\n")
  end

  defp tick(_elapsed, _quiet, _buffer), do: :ok

  defp answer?(buffer, question) do
    buffer |> presence(question)
  end

  defp presence(buffer, question) when byte_size(buffer) > 0 do
    question |> removed?(buffer)
  end

  defp presence(_buffer, _question), do: false

  defp full?(buffer), do: byte_size(buffer) > 0

  defp removed?(question, buffer) do
    buffer |> polish() |> replace(question, "") |> trim() |> full?()
  end

  defp polish(buffer) do
    buffer |> safe() |> clean()
  end

  defp safe(buffer) do
    buffer |> validate() |> native()
  end

  defp validate(buffer) do
    :unicode.characters_to_binary(buffer, :utf8, :utf8)
  end

  defp native(r) when is_binary(r), do: r
  defp native({:incomplete, v, _}), do: v
  defp native({:error, v, _}), do: v

  defp reply(buffer) do
    write("collect done bytes=#{byte_size(buffer)}\n")
    buffer |> polish() |> final()
  end

  defp final(stripped) do
    stripped |> noclutter() |> trim() |> pick(stripped)
  end

  defp pick(cleaned, _stripped) when byte_size(cleaned) > 20, do: cleaned
  defp pick(_cleaned, stripped), do: stripped

  defp noclutter(text) do
    text
    |> replace(~r/\(esc to interrupt\)/i, "")
    |> replace(~r/·\s+\w+…/, "")
    |> replace(~r/Type \? for shortcuts[^\n]*/i, "")
    |> replace(~r/Press [Ctrl\+C]+ to exit[^\n]*/i, "")
    |> replace(~r/\(type .+ for help\)[^\n]*/i, "")
    |> replace(~r/[┌┐└┘─│├┤┬┴┼]/, "")
    |> replace(~r/\s+/, " ")
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

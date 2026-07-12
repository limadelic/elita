defmodule El.Puppet.Answer do
  import El.Pty, only: [inject: 2, watch: 2, unwatch: 2]
  import El.Log, only: [write: 1]
  import El.Puppet.Collect, only: [collect: 1]
  import GenServer, only: [cast: 2]
  import System, only: [monotonic_time: 1]
  import String, only: [trim: 1, slice: 2]
  import :global, only: [whereis_name: 1]
  import Map, only: [merge: 2]

  def reply(pty, sender, message) do
    watch(pty, self())
    act(pty, sender, message)
  catch
    :exit, _ -> write("✨ reply exit\n")
  end

  defp act(pty, sender, message) do
    inject(pty, message <> "\r")
    respond(pty, sender, message)
  end

  defp respond(pty, sender, message) do
    response = collect(build(pty, message, monotonic_time(:millisecond)))
    unwatch(pty, self())
    write("✨ ask reply collected: #{inspect(slice(inspect(response), 0..50))}\n")
    signal(sender, format(response))
  end

  defp format(response) when is_list(response), do: pull(response)
  defp format(response) when is_binary(response), do: response
  defp format(response), do: inspect(response)

  defp pull([%{"text" => text} | _]), do: text
  defp pull(response), do: inspect(response)

  defp signal(sender, response) do
    text = envelope(sender, response)
    write("✨ ask reply to: #{inspect(sender)} text: #{inspect(text)}\n")
    direct(sender, text)
  end

  defp envelope(sender, response) do
    name = trim(to_string(sender))
    mark = "[reply #{name}]"
    "#{mark}\n#{response}"
  end

  defp direct(addr, text) do
    addr |> locate() |> deliver(text)
  end

  defp deliver(nil, _text) do
    write("direct nil: cannot deliver\n")
  end

  defp deliver(pid, text), do: cast(pid, {:put, text})

  defp locate(addr), do: target(addr)

  defp target(name) when is_atom(name) do
    lookup(name) |> found()
  rescue
    _ -> nil
  end

  defp lookup(name), do: whereis_name({name, :puppet})

  defp found(:undefined), do: nil
  defp found(pid), do: pid

  defp build(pty, message, now) do
    base(pty, message) |> timing(now)
  end

  defp base(pty, message) do
    %{pty: pty, buffer: "", question: message, burst: 1, gap: false}
  end

  defp timing(map, now) do
    merge(map, %{last: now, start: now})
  end
end

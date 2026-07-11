defmodule El.Wrap.Remote do
  @moduledoc false
  import El.Distribution, only: [target: 1, wait: 1]
  import String, only: [to_atom: 1, trim: 1, trim_trailing: 2]
  import El.Puppet, only: [ask: 2, put: 2]
  import El.Log, only: [write: 1]

  def deliver(name, message, sender) do
    prepare(name, sender) |> wait() |> query(message, sender)
  catch
    :exit, reason -> (write("deliver exit: #{inspect(reason)}\n"); :forward)
  end

  defp prepare(name, sender) do
    target = name |> trim() |> to_atom()
    write("prepare: target=#{target} from=#{inspect(sender)}\n")
    target
  end

  defp query(nil, _message, _sender), do: :forward

  defp query(pid, message, sender) do
    respond(call(pid, message), sender)
  catch
    :exit, reason -> (write("query exit: #{inspect(reason)}\n"); :forward)
  end

  defp call(pid, message) when node(pid) == node() do
    ask(pid, message)
  end

  defp call(pid, message) do
    caller = self()
    write("ask to #{node(pid)} from #{inspect(caller)}\n")
    spawn(fn -> watch(caller) end)
    result = :erpc.call(node(pid), El.Puppet, :ask, [pid, message], 90_000)
    write("ask ok\n")
    result
  rescue
    _e -> (write("ask fail exception\n"); :forward)
  catch
    k, _r -> (write("ask fail #{k}\n"); :forward)
  end

  defp watch(pid) do
    write("watchdog armed for #{inspect(pid)}\n"); Process.monitor(pid); receive do {:DOWN, _, _, _, r} -> write("DOWN: #{inspect(r)}\n") end
  end

  defp respond(:forward, _sender), do: :forward

  defp respond(output, sender) do
    agent = sender |> fix(sender)
    route(agent |> target(), output, agent)
    {:handled}
  end

  defp fix(atom, _) when is_atom(atom), do: atom
  defp fix(_, binary) when is_binary(binary), do: to_atom(binary)

  defp route(nil, _output, _agent) do
    write("route nil: cannot write\n")
    :ok
  end

  defp route(pid, output, agent) when is_list(output) do
    text = extract(output)
    route(pid, text, agent)
  end

  defp route(pid, output, agent) when is_binary(output) do
    cleaned = trim_trailing(output, "\n")
    write("route to: #{inspect(pid)} text: #{inspect(cleaned)}\n")
    put(pid, cleaned)
    File.write("/dev/stdout", "#{agent}> ")
  end

  defp route(_pid, output, _agent) do
    write("route drop: #{inspect(output)}\n")
    :ok
  end

  defp extract([%{"text" => text} | _]), do: text
  defp extract(_), do: ""

  def known?(name) do
    name |> trim() |> to_atom() |> target() |> is_pid()
  rescue
    _ -> false
  end
end

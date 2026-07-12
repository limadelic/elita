defmodule El.Wrap.Remote do
  @moduledoc false
  import El.Distribution, only: [target: 1, wait: 1]
  import String, only: [to_atom: 1, trim: 1, trim_trailing: 2]
  import El.Puppet, only: [ask: 2, put: 2]
  import El.Log, only: [write: 1]
  import File, only: [write: 2]

  def deliver(name, message, sender) do
    prepare(name, sender) |> wait() |> query(message, sender)
  catch
    :exit, _ ->
      write("deliver exit\n")
      :forward
  end

  defp prepare(name, sender) do
    t = name |> trim() |> to_atom()
    write("prepare: target=#{t} from=#{inspect(sender)}\n")
    t
  end

  defp query(nil, _, _), do: :forward

  defp query(pid, msg, sender) do
    respond(call(pid, msg), sender)
  catch
    :exit, _ ->
      write("query exit\n")
      :forward
  end

  defp call(pid, msg) when node(pid) == node(), do: ask(pid, msg)

  defp call(pid, msg) do
    write("ask to #{node(pid)} from #{inspect(self())}\n")
    guard(pid, msg)
  end

  defp guard(pid, msg) do
    spawn(fn -> monitor(self()) end)
    attempt(pid, msg)
  rescue
    _ -> fail("exception")
  catch
    k, _ -> fail("#{k}")
  end

  defp fail(reason) do
    write("ask fail #{reason}\n")
    :forward
  end

  defp attempt(pid, msg) do
    pid
    |> node()
    |> then(fn n -> :erpc.call(n, El.Puppet, :ask, [pid, msg], 90_000) end)
    |> tap(fn _ -> write("ask ok\n") end)
  end

  defp monitor(pid) do
    Process.monitor(pid)

    receive do
      {:DOWN, _, _, _, r} -> write("DOWN: #{inspect(r)}\n")
    end
  end

  defp respond(:forward, _), do: :forward

  defp respond(output, sender) do
    agent = fix(sender, sender)
    route(target(agent), output, agent)
    {:handled}
  end

  defp fix(a, _) when is_atom(a), do: a
  defp fix(_, b) when is_binary(b), do: to_atom(b)

  defp route(nil, _, _) do
    write("route nil: cannot write\n")
    :ok
  end

  defp route(pid, [%{"text" => text} | _], agent) do
    route(pid, text, agent)
  end

  defp route(pid, output, agent) when is_binary(output) do
    cleaned = trim_trailing(output, "\n")
    write("route to: #{inspect(pid)} text: #{inspect(cleaned)}\n")
    put(pid, cleaned)
    write("/dev/stdout", "#{agent}> ")
  end

  defp route(_, output, _) do
    write("route drop: #{inspect(output)}\n")
    :ok
  end

  def known?(name) do
    name |> trim() |> to_atom() |> target() |> is_pid()
  rescue
    _ -> false
  end
end

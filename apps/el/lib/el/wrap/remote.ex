defmodule El.Wrap.Remote do
  @moduledoc false
  import El.Distribution, only: [target: 1, wait: 1]
  import String, only: [to_atom: 1, trim: 1, trim_trailing: 2, split: 3]
  import El.Puppet, only: [put: 2]
  import El.Log, only: [write: 1]
  import File, only: [write: 2]
  import El.Pty, only: [watch: 2, unwatch: 2]
  import El.Puppet.Collect, only: [collect: 1]
  import System, only: [monotonic_time: 1]

  def deliver(name, message, sender) do
    prepare(name, sender) |> wait() |> query(message, sender)
  catch
    :exit, _ ->
      write("deliver exit\n")
      :forward
  end

  defp query(nil, _, _), do: :forward

  defp query(target, message, sender) do
    respond(gather(target, message, sender), sender)
  catch
    :exit, _ ->
      write("query exit\n")
      :forward
  end

  defp gather(pid, msg, sender) do
    text = "[ask #{sender |> fix(sender) |> to_string()}]\n#{msg}"
    write("gather: ask to #{inspect(pid)} text: #{inspect(text)}\n")
    put(pid, text)
    listen(sender, sender)
  end

  defp listen(pty, sender) do
    watch(pty, self())
    task = Task.async(fn -> collect(build(pty, sender, monotonic_time(:millisecond))) end)
    result = await(task)
    unwatch(pty, self())
    result
  end

  defp await(task) do
    Task.await(task, 90_000)
  rescue
    _ -> timed(task)
  catch
    :exit, {:timeout, _} -> timed(task)
    :exit, _ -> failed(task)
  end

  defp timed(task) do
    Task.shutdown(task, 1)
    write("listen fail: ask-on-tell timeout after 90s\n")
    :forward
  end

  defp failed(task) do
    Task.shutdown(task, 1)
    :forward
  end

  defp build(pty, _sender, now) do
    %{pty: pty, buffer: "", last: now, start: now, question: "ask_response", burst: 1, gap: false}
  end

  def tell(name, message, sender) do
    prepare(name, sender) |> wait() |> inject(message, sender)
  catch
    :exit, reason ->
      write("tell exit: #{inspect(reason)}\n")
      :forward
  end

  defp prepare(name, sender) do
    t = name |> trim() |> to_atom()
    write("prepare: target=#{t} from=#{inspect(sender)}\n")
    t
  end

  defp inject(nil, _message, _sender), do: :forward

  defp inject(pid, message, sender) do
    text = "[from #{sender |> fix(sender) |> to_string()}]\n#{message}"
    write("inject to: #{inspect(pid)} text: #{inspect(text)}\n")
    put(pid, text)
  end

  defp respond(:forward, _), do: :forward

  defp respond(output, sender) do
    extracted = extract(output)
    agent = fix(sender, sender)
    route(target(agent), extracted, agent)
    {:handled}
  end

  defp extract(binary) when is_binary(binary),
    do: binary |> split("\n", parts: 2) |> reply(binary)

  defp extract(other), do: other

  defp reply(["[reply " <> rest, message], _original),
    do: rest |> split("]", parts: 2) |> body(message)

  defp reply(_, original), do: original

  defp body([_sender, ""], message), do: message
  defp body(_, original), do: original

  defp fix(a, _) when is_atom(a), do: a
  defp fix(_, b) when is_binary(b), do: to_atom(b)

  defp route(nil, _, _) do
    write("route nil: cannot write\n")
    :ok
  end

  defp route(pid, [%{"text" => text} | _], agent), do: route(pid, text, agent)

  defp route(_pid, output, agent) when is_binary(output) do
    cleaned = trim_trailing(output, "\n")
    write("route: text: #{inspect(cleaned)}\n")
    write("/dev/stdout", "#{cleaned}\n#{agent}> ")
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

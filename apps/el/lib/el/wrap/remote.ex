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
    target = prepare(name, sender) |> wait()
    ask_tell(target, message, sender)
  catch
    :exit, _ -> halt("deliver")
  end

  defp ask_tell(nil, _, _), do: :forward

  defp ask_tell(target, message, sender) do
    respond(gather(target, message, sender), sender)
  catch
    :exit, _ -> halt("ask_tell")
  end

  defp gather(pid, msg, sender) do
    name = sender |> fix(sender) |> to_string()
    envelope = "[ask #{name}]"
    text = "#{envelope}\n#{msg}"
    write("gather: ask to #{inspect(pid)} text: #{inspect(text)}\n")
    put(pid, text)
    await_response(sender)
  end

  defp await_response(sender) do
    listen(sender, sender)
  end

  defp listen(pty, sender) do
    watch(pty, self())
    result = collect(build(pty, sender, monotonic_time(:millisecond)))
    unwatch(pty, self())
    result
  catch
    :exit, _ ->
      write("listen exit\n")
      unwatch(pty, self())
      :forward
  end

  defp build(pty, _sender, now) do
    %{pty: pty, buffer: "", last: now, start: now,
      question: "ask_response", burst: 1, gap: false}
  end

  defp halt(context) do
    fold("#{context} exit\n")
  end

  defp fold(msg) do
    write(msg)
    :forward
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
    name = sender |> fix(sender) |> to_string()
    envelope = "[from #{name}]"
    text = "#{envelope}\n#{message}"
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

  defp extract(binary) when is_binary(binary) do
    case split(binary, "\n", parts: 2) do
      ["[reply " <> rest, message] ->
        case split(rest, "]", parts: 2) do
          [_sender, ""] -> message
          _ -> binary
        end
      _ -> binary
    end
  end

  defp extract(other), do: other

  defp fix(a, _) when is_atom(a), do: a
  defp fix(_, b) when is_binary(b), do: to_atom(b)

  defp route(nil, _, _) do
    write("route nil: cannot write\n")
    :ok
  end

  defp route(pid, [%{"text" => text} | _], agent) do
    route(pid, text, agent)
  end

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

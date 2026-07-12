defmodule El.Wrap.Remote do
  @moduledoc false
  import El.Distribution, only: [target: 1, wait: 1]
  import String, only: [to_atom: 1, trim: 1, trim_trailing: 2]
  import El.Puppet, only: [put: 2]
  import El.Log, only: [write: 1]
  import File, only: [write: 2]
  import El.Wrap.Rpc, only: [call: 2]

  def deliver(name, message, sender) do
    prepare(name, sender) |> wait() |> query(message, sender)
  catch
    :exit, _ -> halt("deliver")
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

  defp query(nil, _, _), do: :forward

  defp query(pid, msg, sender) do
    respond(call(pid, msg), sender)
  catch
    :exit, _ -> halt("query")
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

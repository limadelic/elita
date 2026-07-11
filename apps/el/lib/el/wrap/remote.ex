defmodule El.Wrap.Remote do
  @moduledoc false
  import El.Distribution, only: [target: 1, wait: 1]
  import String, only: [to_atom: 1, trim: 1, split: 2]
  import Enum, only: [drop: 2, join: 2]
  import El.Puppet, only: [ask: 2, put: 2]
  import El.Log, only: [write: 1]

  def deliver(name, message, sender) do
    prepare(name, sender) |> wait() |> query(message, sender)
  catch
    :exit, _ -> :forward
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
    :exit, _ -> :forward
  end

  defp call(pid, message) when node(pid) == node() do
    ask(pid, message)
  end

  defp call(pid, message) do
    write("ask to #{node(pid)}\n")
    :erpc.call(node(pid), El.Puppet, :ask, [pid, message])
    write("ask ok\n")
  rescue
    _ -> (write("ask fail\n"); :forward)
  end

  defp respond(:forward, _sender), do: :forward

  defp respond(output, sender) do
    pid = sender |> to_atom() |> target()
    route(pid, output)
    {:handled}
  end

  defp route(nil, _output) do
    write("route nil: cannot write\n")
    :ok
  end

  defp route(pid, output) do
    cleaned = output |> split("\n") |> drop(-1) |> join("\n")
    write("route to: #{inspect(pid)} text: #{inspect(cleaned)}\n")
    put(pid, cleaned)
  end

  def known?(name) do
    name |> trim() |> to_atom() |> target() |> is_pid()
  rescue
    _ -> false
  end
end

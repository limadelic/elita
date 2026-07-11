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

  defp prepare(name, _sender) do
    name |> trim() |> to_atom()
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
    note(erpc(node(pid), pid, message))
  rescue
    _ -> :forward
  end

  defp note(result) do
    write("erpc done: #{inspect(result)}\n")
    result
  end

  defp erpc(host, pid, message) do
    :erpc.call(host, El.Puppet, :ask, [pid, message])
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

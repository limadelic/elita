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
    write("deliver #{target} from #{inspect(sender)}\n")
    target
  end

  defp query(nil, _message, _sender), do: :forward

  defp query(pid, message, sender) do
    output = pid |> call(message)
    respond(output, sender)
  catch
    :exit, _ -> :forward
  end

  defp call(pid, message) when node(pid) == node() do
    write("call local ask pid=#{inspect(pid)}\n")
    ask(pid, message)
  end

  defp call(pid, message) do
    audit(pid)
    result = erpc(node(pid), pid, message)
    write("erpc result: #{inspect(result)}\n")
    result
  end

  defp audit(pid) do
    write("call erpc to #{node(pid)} pid=#{inspect(pid)}\n")
  end

  defp erpc(host, pid, message) do
    :erpc.call(host, El.Puppet, :ask, [pid, message])
  rescue
    e -> trap(e, __STACKTRACE__)
  end

  defp trap(error, trace) do
    write("erpc error: #{inspect(error)}\n")
    reraise(error, trace)
  end

  defp respond(:forward, _sender), do: :forward

  defp respond(output, sender) do
    pid = sender |> to_atom() |> target()
    route(pid, output)
    {:handled}
  end

  defp route(nil, _output), do: :ok

  defp route(pid, output) do
    put(pid, output |> split("\n") |> drop(-1) |> join("\n"))
  end

  def known?(name) do
    name |> trim() |> to_atom() |> target() |> is_pid()
  rescue
    _ -> false
  end
end

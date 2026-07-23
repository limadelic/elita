defmodule Matrix.Wrap.Remote do
  @moduledoc false
  import Matrix.Log, only: [write: 1]
  import Matrix.Pty, only: [watch: 2, unwatch: 2]
  import System, only: [monotonic_time: 1]
  import Matrix.Wrap.Reply, only: [handle: 2, fix: 2, prepare: 2, inject: 4]
  import Matrix.Wrap.Guard, only: [await: 1]
  import Map, only: [merge: 2]
  import Task, only: [async: 1]

  def deliver(name, message, sender) do
    invoke(name, message, sender)
  catch
    :exit, _ -> trap("deliver exit\n")
  end

  defp invoke(name, message, sender) do
    target = prepare(name, sender) |> El.Distribution.wait()
    query(target, name, message, sender)
  end

  defp query(nil, _, _, _), do: :forward

  defp query(target, name, message, sender) do
    fetch(target, name, message, sender)
  catch
    :exit, _ -> trap("query exit\n")
  end

  defp fetch(target, name, message, sender) do
    handle(gather(target, message, sender, name), sender)
  end

  defp gather(pid, msg, sender, _target) do
    text = "[ask #{sender |> fix(sender) |> to_string()}]\n#{msg}"
    El.Puppet.put(pid, text)
    listen(sender, sender)
  end

  defp listen(pty, sender) do
    watch(pty, self())
    spawn(pty, sender) |> reap(pty)
  end

  defp spawn(pty, sender) do
    async(fn -> El.Puppet.Collect.collect(build(pty, sender, monotonic_time(:millisecond))) end)
  end

  defp reap(task, pty) do
    result = await(task)
    unwatch(pty, self())
    result
  end

  defp build(pty, _sender, now) do
    %{pty: pty, buffer: "", question: "ask_response", burst: 1, gap: false}
    |> merge(%{last: now, start: now})
  end

  defp trap(msg) do
    write(msg)
    :forward
  end

  def tell(name, message, sender) do
    dispatch(name, message, sender)
  catch
    :exit, reason -> trap("tell exit: #{inspect(reason)}\n")
  end

  defp dispatch(name, message, sender) do
    target = prepare(name, sender) |> El.Distribution.wait()
    inject(target, name, message, sender)
  end
end

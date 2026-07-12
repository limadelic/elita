defmodule El.Wrap.Remote do
  @moduledoc false
  import El.Distribution, only: [wait: 1]
  import El.Puppet, only: [put: 2]
  import El.Log, only: [write: 1]
  import El.Pty, only: [watch: 2, unwatch: 2]
  import El.Puppet.Collect, only: [collect: 1]
  import System, only: [monotonic_time: 1]
  import El.Wrap.Reply, only: [handle: 2, fix: 2, prepare: 2, inject: 3]
  import Map, only: [merge: 2]

  def deliver(name, message, sender) do
    invoke(name, message, sender)
  catch
    :exit, _ ->
      write("deliver exit\n")
      :forward
  end

  defp invoke(name, message, sender) do
    prepare(name, sender) |> wait() |> query(message, sender)
  end

  defp query(nil, _, _), do: :forward

  defp query(target, message, sender) do
    fetch(target, message, sender)
  catch
    :exit, _ ->
      write("query exit\n")
      :forward
  end

  defp fetch(target, message, sender) do
    handle(gather(target, message, sender), sender)
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
    base(pty) |> timing(now)
  end

  defp base(pty) do
    %{pty: pty, buffer: "", question: "ask_response", burst: 1, gap: false}
  end

  defp timing(map, now) do
    merge(map, %{last: now, start: now})
  end

  def tell(name, message, sender) do
    dispatch(name, message, sender)
  catch
    :exit, reason ->
      write("tell exit: #{inspect(reason)}\n")
      :forward
  end

  defp dispatch(name, message, sender) do
    prepare(name, sender) |> wait() |> inject(message, sender)
  end
end

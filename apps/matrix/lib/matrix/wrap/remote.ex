defmodule Matrix.Wrap.Remote do
  @moduledoc false
  import Matrix.Log, only: [write: 1]
  import Matrix.Pty, only: [watch: 2, unwatch: 2]
  import System, only: [monotonic_time: 1]
  import Matrix.Wrap.Reply, only: [handle: 2, fix: 2, prepare: 2, inject: 4]
  import Matrix.Wrap.Guard, only: [await: 1]
  import Map, only: [merge: 2]
  import Task, only: [async: 1]

  def deliver(name, message, sender, opts \\ []) do
    invoke(name, message, sender, opts)
  catch
    :exit, _ -> trap("deliver exit\n")
  end

  defp invoke(name, message, sender, opts) do
    wait_fn = opts[:wait]
    target = prepare(name, sender) |> wait_fn.()
    query(target, name, message, sender, opts)
  end

  defp query(nil, _, _, _, _opts), do: :forward

  defp query(target, name, message, sender, opts) do
    fetch(target, name, message, sender, opts)
  catch
    :exit, _ -> trap("query exit\n")
  end

  defp fetch(target, name, message, sender, opts) do
    handle(gather(target, message, sender, name, opts), sender)
  end

  defp gather(pid, msg, sender, _target, opts) do
    put_fn = opts[:put]
    text = "[ask #{sender |> fix(sender) |> to_string()}]\n#{msg}"
    put_fn.(pid, text)
    listen(sender, sender, opts)
  end

  defp listen(pty, sender, opts) do
    watch(pty, self())
    task(pty, sender, opts) |> reap(pty)
  end

  defp task(pty, sender, opts) do
    collect_fn = opts[:collect]
    async(fn -> collect_fn.(build(pty, sender, monotonic_time(:millisecond))) end)
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

  def tell(name, message, sender, opts \\ []) do
    dispatch(name, message, sender, opts)
  catch
    :exit, reason -> trap("tell exit: #{inspect(reason)}\n")
  end

  defp dispatch(name, message, sender, opts) do
    wait_fn = opts[:wait]
    target = prepare(name, sender) |> wait_fn.()
    inject(target, name, message, sender)
  end
end

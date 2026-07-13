defmodule El.Puppet.Query do
  import El.Pty, only: [watch: 2, inject: 2]
  import El.Log, only: [write: 1]
  import El.Puppet.Collect, only: [collect: 1]
  import Exception, only: [message: 1]
  import System, only: [monotonic_time: 1]
  import Map, only: [merge: 2]

  def call(pty, message), do: safe(pty, message)

  defp safe(pty, message) do
    guarded(pty, message)
  end

  defp guarded(pty, message) do
    gate(pty, message)
  rescue
    e -> trap(e, __STACKTRACE__)
  end

  defp gate(pty, message) do
    perform(pty, message)
  catch
    k, r -> settle(k, r, __STACKTRACE__)
  end

  defp trap(e, stack) do
    write("query exception: #{message(e)}\n")
    reraise e, stack
  end

  defp settle(k, r, stack) do
    write("query caught: #{k} #{inspect(r)}\n")
    :erlang.raise(k, r, stack)
  end

  defp perform(pty, message) do
    setup(pty, message)
    collect(build(pty, message, monotonic_time(:millisecond)))
  end

  defp setup(pty, message) do
    write("query on #{inspect(self())} (node #{inspect(node())})\n")
    write("📢 inject to pty: #{inspect(message)}\n")
    watch(pty, self())
    inject(pty, message <> "\r")
  end

  defp build(pty, message, now) do
    base(pty, message) |> timing(now)
  end

  defp base(pty, message) do
    %{pty: pty, buffer: "", question: message, burst: 1, gap: false}
  end

  defp timing(map, now) do
    merge(map, %{last: now, start: now})
  end
end

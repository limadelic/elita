defmodule El.Puppet.Query do
  import El.Pty, only: [watch: 2, inject: 2]
  import El.Log, only: [write: 1]
  import El.Puppet.Collect, only: [collect: 1]
  import Exception, only: [message: 1]
  import System, only: [monotonic_time: 1]
  import Map, only: [merge: 2]

  def call(pty, message) do
    safe(pty, message)
  end

  defp safe(pty, message) do
    perform(pty, message)
  rescue
    e -> reject(e, __STACKTRACE__)
  catch
    k, r ->
      write("query caught: #{k} #{inspect(r)}\n")
      :erlang.raise(k, r, __STACKTRACE__)
  end

  defp reject(e, stack) do
    write("query exception: #{message(e)}\n")
    reraise e, stack
  end

  defp perform(pty, message) do
    setup(pty, message)
    collect(build(pty, message, monotonic_time(:millisecond)))
  end

  defp setup(pty, message) do
    write("query on #{inspect(self())} (node #{inspect(node())})\n")
    write("inject to pty: #{inspect(message)}\n")
    watch(pty, self())
    inject(pty, message <> "\r")
  end

  defp build(pty, message, now) do
    state(pty, message, now)
  end

  defp state(pty, message, now) do
    %{pty: pty, buffer: "", last: now, start: now}
    |> merge(%{question: message, burst: 1, gap: false})
  end
end

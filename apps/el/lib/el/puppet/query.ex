defmodule El.Puppet.Query do
  import El.Pty, only: [watch: 2, inject: 2]
  import El.Log, only: [write: 1]
  import El.Puppet.Collect, only: [collect: 1]
  import Exception, only: [message: 1]
  import System, only: [monotonic_time: 1]

  def call(pty, message), do: safe(pty, message)

  defp safe(pty, message) do
    perform(pty, message)
  rescue
    e ->
      write("query exception: #{message(e)}\n")
      reraise e, __STACKTRACE__
  catch
    k, r ->
      write("query caught: #{k} #{inspect(r)}\n")
      :erlang.raise(k, r, __STACKTRACE__)
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
    %{pty: pty, buffer: "", last: now, start: now, question: message, burst: 1, gap: false}
  end
end

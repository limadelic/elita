defmodule El.Puppet.Query do
  import El.Pty, only: [watch: 2, inject: 2]
  import El.Log, only: [write: 1]
  import El.Puppet.Collect, only: [collect: 1]
  import Exception, only: [message: 1]
  import System, only: [monotonic_time: 1]

  def call(pty, message) do
    write("query on #{inspect(self())} (node #{inspect(node())})\n")
    write("inject to pty: #{inspect(message)}\n")
    watch(pty, self())
    write("watched pty, caller self() = #{inspect(self())}\n")
    inject(pty, message <> "\r")
    now = monotonic_time(:millisecond)

    state = %{
      pty: pty,
      buffer: "",
      last: now,
      start: now,
      question: message,
      burst: 1,
      gap: false
    }

    collect(state)
  rescue
    e ->
      write("query exception: #{message(e)}\n")
      reraise e, __STACKTRACE__
  catch
    kind, reason ->
      write("query caught: #{kind} #{inspect(reason)}\n")
      :erlang.raise(kind, reason, __STACKTRACE__)
  end
end

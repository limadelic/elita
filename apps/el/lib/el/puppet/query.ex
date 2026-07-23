defmodule El.Puppet.Query do
  import Matrix.Pty, only: [watch: 2, inject: 2]
  import El.Log, only: [write: 1]
  import Exception, only: [message: 1]

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
    :erlang.raise(k, r, stack)
  end

  defp perform(pty, message) do
    setup(pty, message)
    []
  end

  defp setup(pty, message) do
    write("query on #{inspect(self())} (node #{inspect(node())})\n")
    write("inject to pty: #{inspect(message)}\n")
    watch(pty, self())
    inject(pty, message <> "\r")
  end
end

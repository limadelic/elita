defmodule Server do
  import :gen_tcp, only: [connect: 4, close: 1]
  import System, only: [monotonic_time: 1]

  @opts [
    :binary,
    {:packet, :line},
    {:active, false},
    {:reuseaddr, true},
    {:nodelay, true}
  ]

  def wait(host, port) do
    retry(host, port, monotonic_time(:millisecond) + 30000)
  end

  defp retry(host, port, deadline) do
    remaining = deadline - monotonic_time(:millisecond)
    go(remaining > 0, host, port, remaining, deadline)
  end

  defp go(false, host, port, _, _) do
    raise "Timeout waiting for freeq server at #{host}:#{port}"
  end

  defp go(true, host, port, remaining, deadline) do
    timeout = min(500, remaining)
    connect(host, port, @opts, timeout) |> proceed(host, port, deadline)
  end

  defp proceed({:ok, socket}, _, _, _) do
    close(socket)
  end

  defp proceed({:error, _}, host, port, deadline) do
    defer(host, port, deadline)
  end

  defp defer(host, port, deadline) do
    receive do
    after
      100 -> retry(host, port, deadline)
    end
  end
end

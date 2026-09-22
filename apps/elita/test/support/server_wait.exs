defmodule ServerWait do
  import :gen_tcp, only: [connect: 4, close: 1]

  def wait(host, port) do
    retry(host, port, System.monotonic_time(:millisecond) + 30000)
  end

  defp retry(host, port, deadline) do
    remaining = deadline - System.monotonic_time(:millisecond)
    go(remaining > 0, host, port, remaining, deadline)
  end

  defp go(false, host, port, _, _) do
    raise "Timeout waiting for freeq server at #{host}:#{port}"
  end

  defp go(true, host, port, remaining, deadline) do
    timeout = min(500, remaining)
    opts = [:binary, {:packet, :line}, {:active, false}, {:reuseaddr, true}, {:nodelay, true}]
    connect(host, port, opts, timeout) |> proceed(host, port, deadline)
  end

  defp proceed({:ok, socket}, _, _, _) do
    close(socket)
  end

  defp proceed({:error, _}, host, port, deadline) do
    delay_retry(host, port, deadline)
  end

  defp delay_retry(host, port, deadline) do
    receive do
    after
      100 -> retry(host, port, deadline)
    end
  end
end

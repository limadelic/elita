#!/usr/bin/env elixir
# Simplified test: two local nodes, test erpc timeout with logging

defmodule SimpleStub do
  @moduledoc "Simple RPC target that sleeps"
  def respond(message, sleep_ms) do
    if sleep_ms > 0 do
      IO.puts("[StubNode] sleeping #{sleep_ms}ms")
      Process.sleep(sleep_ms)
    end
    IO.puts("[StubNode] responding to: #{message}")
    {:ok, "response to #{message}"}
  end
end

# Main test
case :net_kernel.start([:main_node, :longnames]) do
  {:ok, _} -> :ok
  {:error, {:already_started, _}} -> :ok
end

IO.puts("[Main] Starting stub node...")

# Start the stub node using erl_call
{:ok, stub_node_pid} = :slave.start(
  ~c"127.0.0.1",
  :stub_node
)

IO.puts("[Main] Slave started: #{inspect(stub_node_pid)}")

# Wait for connection
Process.sleep(500)

stub_node = :"stub_node@127.0.0.1"

# Test 1: Normal response
IO.puts("\n=== TEST 1: Normal (0ms) ===")
start = :os.system_time(:millisecond)

try do
  result = :erpc.call(stub_node, SimpleStub, :respond, ["test1", 0], 90_000)
  elapsed = :os.system_time(:millisecond) - start
  IO.inspect({:ok, elapsed, result}, label: "TEST1 SUCCESS")
rescue
  e ->
    elapsed = :os.system_time(:millisecond) - start
    IO.inspect({:error, elapsed, e}, label: "TEST1 RESCUE")
catch
  k, r ->
    elapsed = :os.system_time(:millisecond) - start
    IO.inspect({:caught, elapsed, k, r}, label: "TEST1 CATCH")
end

# Test 2: Timeout (120s sleep, 90s timeout)
IO.puts("\n=== TEST 2: Timeout (120s sleep, 90s timeout) ===")
start = :os.system_time(:millisecond)

try do
  result = :erpc.call(stub_node, SimpleStub, :respond, ["test2", 120_000], 90_000)
  elapsed = :os.system_time(:millisecond) - start
  IO.inspect({:ok, elapsed, result}, label: "TEST2 SUCCESS")
rescue
  e ->
    elapsed = :os.system_time(:millisecond) - start
    IO.inspect({:error, elapsed, e}, label: "TEST2 RESCUE")
catch
  k, r ->
    elapsed = :os.system_time(:millisecond) - start
    IO.inspect({:caught, elapsed, k, r}, label: "TEST2 CATCH")
end

IO.puts("\n[Main] Tests complete")
:slave.stop(stub_node_pid)

#!/usr/bin/env elixir
# Test script to reproduce erpc timeout and logging behavior
# Runs two local nodes and tests Remote.deliver call path

defmodule StubPuppet do
  @moduledoc "Stub puppet that responds or sleeps based on mode"
  use GenServer

  def start(sleep_ms) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, sleep_ms, name: :stub_puppet)
  end

  def ask(pid, message) do
    GenServer.call(pid, {:ask, message}, :infinity)
  end

  def init(sleep_ms) do
    {:ok, sleep_ms}
  end

  def handle_call({:ask, message}, _from, sleep_ms) do
    if sleep_ms > 0 do
      IO.puts("[StubPuppet] Sleeping #{sleep_ms}ms before responding to: #{message}")
      Process.sleep(sleep_ms)
    end
    reply = "pong: #{message}"
    IO.puts("[StubPuppet] Replying: #{reply}")
    {:reply, reply, sleep_ms}
  end
end

defmodule TestLogger do
  @moduledoc "Simple logger that writes to file and stdout"
  use GenServer

  def start(node_name) do
    log_file = "/tmp/test_erpc_#{node_name}.log"
    File.write(log_file, "=== Test started for #{node_name} ===\n")
    {:ok, _pid} = GenServer.start_link(__MODULE__, log_file, name: :test_logger)
  end

  def write(msg) do
    try do
      GenServer.cast(:test_logger, {:write, msg})
    rescue
      _ -> :ok
    end
  end

  def init(log_file) do
    {:ok, log_file}
  end

  def handle_cast({:write, msg}, log_file) do
    timestamp = :os.system_time(:millisecond)
    line = "[#{timestamp}] #{msg}"
    IO.write(line)
    File.write(log_file, line <> "\n", [:append])
    {:noreply, log_file}
  end
end

defmodule TestRemote do
  @moduledoc "Simplified Remote.call for testing"
  import TestLogger, only: [write: 1]

  def deliver(target_node, message) do
    write("deliver: calling #{target_node}\n")
    call(target_node, message)
  end

  defp call(_target, _message) do
    write("call: before erpc\n")
    result = :erpc.call(:stub_node, :erlang, :apply, [fn -> ask_puppet(message) end, []], 90_000)
    write("call: after erpc result=#{inspect(result)}\n")
    result
  rescue
    e ->
      write("call: rescue exception=#{inspect(e)}\n")
      :forward
  catch
    k, r ->
      write("call: catch #{k} reason=#{inspect(r)}\n")
      :forward
  end

  defp ask_puppet(message) do
    write("ask_puppet: calling stub_puppet on #{node()}\n")
    GenServer.call(:stub_puppet, {:ask, message}, :infinity)
  end
end

# Main test
defmodule Test do
  def run do
    IO.puts("Starting test nodes...")

    # Start test logger on main node
    TestLogger.start("main")

    # Start stub node with distributed erlang
    {:ok, _pid} = :net_kernel.start([:main_node, :longnames])

    # Start stub node
    {:ok, stub_pid} = :slave.start(
      ~c"127.0.0.1",
      :stub_node,
      "-pa #{:code.get_path() |> Enum.join(" ")} -noshell"
    )

    IO.puts("Stub node started: #{inspect(stub_pid)}")

    # Connect nodes
    :net_kernel.connect_node(:stub_node@127.0.0.1)

    # Setup stub node
    :rpc.call(:stub_node@127.0.0.1, TestLogger, :start, [:stub])
    :rpc.call(:stub_node@127.0.0.1, StubPuppet, :start, [0])  # No sleep for normal case

    # Test 1: Normal response (should get "ask ok")
    IO.puts("\n=== TEST 1: Normal response (0ms sleep) ===")
    TestLogger.write("test1: starting normal ask\n")

    # We need to call the actual Remote code path
    # For now, just test erpc.call directly
    test_erpc_normal()

    Process.sleep(500)

    # Test 2: Timeout case (should get "ask fail" at 90s)
    IO.puts("\n=== TEST 2: Timeout case (120s sleep) ===")
    TestLogger.write("test2: setting up 120s sleep case\n")
    :rpc.call(:stub_node@127.0.0.1, StubPuppet, :start, [120_000])

    test_erpc_timeout()

    # Show log files
    IO.puts("\n=== Log files ===")
    show_logs()

    # Cleanup
    :slave.stop(stub_pid)
  end

  defp test_erpc_normal do
    TestLogger.write("test: before erpc.call (normal)\n")

    result = :erpc.call(
      :stub_node@127.0.0.1,
      :erlang,
      :apply,
      [fn -> GenServer.call(:stub_puppet, {:ask, "test1"}, :infinity) end, []],
      90_000
    )

    TestLogger.write("test: after erpc.call result=#{inspect(result)}\n")
    result
  rescue
    e ->
      TestLogger.write("test: rescue #{inspect(e)}\n")
      :error
  catch
    k, r ->
      TestLogger.write("test: catch #{k} #{inspect(r)}\n")
      :error
  end

  defp test_erpc_timeout do
    TestLogger.write("test: before erpc.call (timeout)\n")
    start_time = :os.system_time(:millisecond)

    result = :erpc.call(
      :stub_node@127.0.0.1,
      :erlang,
      :apply,
      [fn -> GenServer.call(:stub_puppet, {:ask, "test2"}, :infinity) end, []],
      90_000
    )

    elapsed = :os.system_time(:millisecond) - start_time
    TestLogger.write("test: after erpc.call (#{elapsed}ms) result=#{inspect(result)}\n")
    result
  rescue
    e ->
      elapsed = :os.system_time(:millisecond) - start_time
      TestLogger.write("test: rescue (#{elapsed}ms) #{inspect(e)}\n")
      :error
  catch
    k, r ->
      elapsed = :os.system_time(:millisecond) - start_time
      TestLogger.write("test: catch (#{elapsed}ms) #{k} #{inspect(r)}\n")
      :error
  end

  defp show_logs do
    ["main", "stub"]
    |> Enum.each(fn node_name ->
      log_file = "/tmp/test_erpc_#{node_name}.log"
      if File.exists?(log_file) do
        IO.puts("\n--- #{log_file} ---")
        File.read!(log_file)
        |> String.trim()
        |> IO.puts()
      end
    end)
  end
end

Test.run()

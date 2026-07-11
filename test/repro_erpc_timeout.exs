# Repro test: Remote.deliver with real erpc timeout behavior
# Prerequisites: mix compile
# Run: elixir test/repro_erpc_timeout.exs

# Add paths so we can load the modules
Code.append_path("/Users/mike/dev/self/elita/malko/apps/el/_build/dev/lib/el/ebin")
Code.append_path("/Users/mike/dev/self/elita/malko/apps/elita/_build/dev/lib/elita/ebin")

IO.puts("[Repro] Paths set")

# Ensure key modules are loaded
Code.ensure_loaded(El.Log)
Code.ensure_loaded(El.Wrap.Remote)
Code.ensure_loaded(El.Distribution)

IO.puts("[Repro] Modules loaded")

# Define stub that responds after delay
defmodule ReproStub do
  use GenServer

  def start_link(sleep_ms) do
    GenServer.start_link(__MODULE__, sleep_ms, name: :repro_stub)
  end

  def init(sleep_ms) do
    {:ok, sleep_ms}
  end

  def handle_call({:ask, message}, _from, sleep_ms) do
    if sleep_ms > 0 do
      IO.puts("[Stub] Sleeping #{sleep_ms}ms")
      Process.sleep(sleep_ms)
    end
    IO.puts("[Stub] Responding to: #{message}")
    {:reply, "pong:#{message}", sleep_ms}
  end
end

# Test 1: Normal response (10ms sleep)
IO.puts("\n=== TEST 1: Normal (10ms sleep) ===")

# Start sender node
{:ok, _} = :net_kernel.start([:sender_node, :longnames])
IO.puts("[Sender] Node started")

# Start receiver node
{:ok, receiver_pid} = :slave.start(~c"127.0.0.1", :receiver_node)
IO.puts("[Sender] Receiver node started: #{inspect(receiver_pid)}")

# Add paths on receiver
:rpc.call(:"receiver_node@127.0.0.1", :code, :add_path, ["/Users/mike/dev/self/elita/malko/apps/el/_build/dev/lib/el/ebin"])
:rpc.call(:"receiver_node@127.0.0.1", :code, :add_path, ["/Users/mike/dev/self/elita/malko/apps/elita/_build/dev/lib/elita/ebin"])

# Start stub on receiver
:rpc.call(:"receiver_node@127.0.0.1", ReproStub, :start_link, [10])
IO.puts("[Sender] Stub started on receiver")

# Sleep a bit for stability
Process.sleep(500)

# Call Remote.deliver from sender to receiver stub
IO.puts("[Sender] Calling Remote.deliver(repro_stub, \"test1\", :sender_node)")
start_time = :os.system_time(:millisecond)

result = try do
  El.Wrap.Remote.deliver("repro_stub", "test1", :sender_node)
rescue
  e ->
    IO.puts("[Sender] RESCUE: #{inspect(e)}")
    {:error, e}
catch
  k, r ->
    IO.puts("[Sender] CATCH #{k}: #{inspect(r)}")
    {:caught, k, r}
end

elapsed = :os.system_time(:millisecond) - start_time
IO.puts("[Sender] Result: #{inspect(result)}, elapsed: #{elapsed}ms")

# Show logs
IO.puts("\n=== LOG FILES ===")
["sender_node", "receiver_node"]
|> Enum.each(fn node_name ->
  log_file = Path.expand("~/.elita/sessions/#{node_name}_*.log")
  matching_files = Path.wildcard(log_file)

  if matching_files != [] do
    matching_files
    |> Enum.each(fn file ->
      IO.puts("\n--- #{file} ---")
      case File.read(file) do
        {:ok, content} -> IO.write(content)
        :error -> IO.puts("(could not read)")
      end
    end)
  else
    IO.puts("\n--- No log files found for #{node_name} ---")
  end
end)

# Cleanup
:slave.stop(receiver_pid)
IO.puts("\n[Repro] Complete")

#!/usr/bin/env elixir
# Test to verify Remote.call logging with erpc timeout
# Focuses on the actual logging behavior

# First, verify that the current code compiles
IO.puts("[Test] Compiling current remote.ex...")

# Mix the project first
File.cd!("/Users/mike/dev/self/elita/malko")
Mix.Project.in_project(:malko, ".", fn _module ->
  # Compile
  Mix.Task.run("compile", [])
end)

IO.puts("[Test] Code compiled successfully")

# Now run a simple test to see if the erpc timeout is actually triggering
IO.puts("\n[Test] Starting erpc timeout test...")

case :net_kernel.start([:test_main, :longnames]) do
  {:ok, _} -> :ok
  {:error, {:already_started, _}} -> :ok
end

# Create a stub that will test timeout
defmodule TestStub do
  def quick_response do
    {:ok, "pong"}
  end

  def slow_response do
    Process.sleep(110_000)
    {:ok, "pong"}
  end
end

# Test without starting slave - just test if erpc timeout parameter works locally
IO.puts("\n[Test] Testing erpc.call with timeout parameter...")

# Test 1: Quick call (should work)
IO.puts("\nTEST 1: Quick erpc.call (local)")
try do
  result = :erpc.call(node(), TestStub, :quick_response, [], 90_000)
  IO.inspect({:success, result}, label: "Result")
rescue
  e ->
    IO.inspect({:rescue, e}, label: "Error")
catch
  k, r ->
    IO.inspect({:catch, k, r}, label: "Caught")
end

IO.puts("\n[Test] Checking if write() logs are appearing...")

# Now let's test if we can actually load the Remote module and see its code
IO.puts("\nLoading Remote module...")
Code.ensure_loaded(El.Wrap.Remote)

# Show the call function
defmodule ShowRemote do
  def show_call_code do
    case :code.get_object_code(El.Wrap.Remote) do
      {_module, binary, _} ->
        IO.puts("Module binary loaded successfully")
        {:ok, binary}
      :error ->
        IO.puts("Could not load module binary")
        :error
    end
  end
end

ShowRemote.show_call_code()

IO.puts("\n[Test] Complete")

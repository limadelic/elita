# Test intercom system
IO.puts("Testing doble9 group spawning and intercom...")

# Spawn doble9 group
IO.puts("Spawning doble9 group...")
doble9_pid = Elita.Manager.ensure("doble9")
IO.puts("doble9 pid: #{inspect(doble9_pid)}")

# Wait a bit for all agents to spawn
Process.sleep(500)

# Check what agents were spawned
agents = ["doble9", "doble9_left", "doble9_top", "doble9_right", "doble9_player"]
Enum.each(agents, fn name ->
  case Registry.lookup(Elita.AgentRegistry, name) do
    [{pid, _}] -> IO.puts("✓ #{name}: #{inspect(pid)}")
    [] -> IO.puts("✗ #{name}: not found")
  end
end)

# Test intercom by having doble9 act
IO.puts("\nTesting doble9 action (should trigger intercom)...")
result = Elita.Agent.act("doble9", "start the game")
IO.puts("Result: #{inspect(result)}")

IO.puts("Test complete!")
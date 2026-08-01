defmodule SpawnTest do
  use SpecHelper
  import ExUnit.Callbacks

  setup do
    # Create temporary test agent folder
    test_agent_dir = System.tmp_dir!() |> Path.join("test_spawn_agent")
    File.mkdir_p!(test_agent_dir)

    # Write minimal agent.md so it shows up in world
    agent_file = Path.join(test_agent_dir, "agent.md")
    File.write!(agent_file, "# Test Agent\n")

    # Configure AGENT_REGISTRATIONS to include test agent
    System.put_env("AGENT_REGISTRATIONS", "spawn_test:#{test_agent_dir}")

    on_exit(fn ->
      File.rm_rf(test_agent_dir)
      System.delete_env("AGENT_REGISTRATIONS")
    end)

    :ok
  end

  test "spawn through el entry point" do
    El.Distribution.start("specs")

    output =
      ExUnit.CaptureIO.capture_io(fn ->
        El.Commands.Spawn.spawn("test_spawn_session", "spawn_test")
      end)

    # In-process seam: El.Commands.Spawn.spawn/2 called directly
    # Entry point processes: resolve agent, check session, start session
    # With a native agent, rouse/2 returns :ok silently
    assert output == ""
  end

  test "spawn unknown agent through el" do
    El.Distribution.start("specs")

    output =
      ExUnit.CaptureIO.capture_io(fn ->
        El.Commands.Spawn.spawn("test_session", "nonexistent")
      end)

    # Entry point handles unknown agents with error message
    assert output =~ "error"
    assert output =~ "unknown agent"
  end
end

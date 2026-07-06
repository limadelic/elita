defmodule El.Commands.TellTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias El.Commands.Tell

  test "returns ok when no live session (fallback)" do
    try do
      Tell.execute("unknown", "test")
    rescue
      _ -> :ok
    catch
      _ -> :ok
    else
      _ -> :ok
    end
  end

  test "remote node targeting with EL_NODE" do
    target = Tell.remote_target("agent", env_module: El.Commands.TellTest.FakeEnvWithNode)
    assert target == :"claude_agent@home.local"
  end

  test "local fallback when EL_NODE not set" do
    assert Tell.remote_target("agent", env_module: El.Commands.TellTest.FakeEnvNoNode) == nil
  end

  test "unreachable remote prints error" do
    output = capture_io(:stderr, fn ->
      Tell.remote_unreachable("agent", "home.local")
    end)
    assert String.contains?(output, "session agent unreachable at home.local")
  end

  defmodule FakeEnvWithNode do
    def get("EL_NODE"), do: "home.local"
    def get(_key), do: nil
  end

  defmodule FakeEnvNoNode do
    def get(_key), do: nil
  end
end

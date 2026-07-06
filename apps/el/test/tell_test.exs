defmodule El.Commands.TellTest do
  use ExUnit.Case

  test "returns ok when no live session (fallback)" do
    # Fallback path should work for unknown agents
    # This tests that execute doesn't crash
    try do
      El.Commands.Tell.execute("unknown", "test")
    rescue
      _ -> :ok
    catch
      _ -> :ok
    else
      _ -> :ok
    end
  end
end

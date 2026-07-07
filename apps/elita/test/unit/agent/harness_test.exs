defmodule Agent.HarnessTest do
  use ExUnit.Case
  @moduletag :main

  test "dispatch returns error for unknown recipient" do
    result = Agent.Harness.dispatch("unknown_agent", "hello", :ask)
    assert result == "unknown: unknown_agent"
  end

  test "dispatch returns error for unknown tell recipient" do
    result = Agent.Harness.dispatch("nonexistent", "message", :tell)
    assert result == "unknown: nonexistent"
  end
end

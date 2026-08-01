defmodule LookupTest do
  use SpecHelper

  test "lookup command finds a spawned native agent" do
    spawn(:greet)

    result = lookup(:greet, "hello")

    verify("who am i talking to", result)
  end

  test "lookup command returns unknown for agent that was never spawned" do
    result = lookup(:phantom, "hello")

    assert result =~ ~r/unknown/i
  end
end

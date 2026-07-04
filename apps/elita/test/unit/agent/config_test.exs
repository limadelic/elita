defmodule Agent.ConfigUnitTest do
  use ExUnit.Case

  setup do
    System.delete_env("AGENT_REGISTRATIONS")
    :ok
  end

  test "load from environment variable" do
    System.put_env("AGENT_REGISTRATIONS", "dude:/Users/mike/dev/self/elita")
    registrations = Agent.Config.load()
    assert registrations == [dude: "/Users/mike/dev/self/elita"]
  end

  test "parse multiple agents" do
    System.put_env("AGENT_REGISTRATIONS", "dude:/path/one,rec:/path/two")
    registrations = Agent.Config.load()
    assert Enum.sort(registrations) == Enum.sort(dude: "/path/one", rec: "/path/two")
  end

  test "return empty list when not configured" do
    registrations = Agent.Config.load()
    assert registrations == []
  end
end

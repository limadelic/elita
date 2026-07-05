defmodule Agent.RegistryUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()
    :ok
  end

  test "register stores agent with name and pid" do
    pid = spawn(fn -> :ok end)
    :ok = Agent.Registry.register(:test_agent, "/path/to/agent", pid)

    assert Agent.Registry.lookup(:test_agent) == {:ok, {pid, "/path/to/agent"}}
  end

  test "lookup returns error for unregistered agent" do
    assert Agent.Registry.lookup(:unknown) == {:error, :not_found}
  end

  test "remove deletes registered agent" do
    pid = spawn(fn -> :ok end)
    Agent.Registry.register(:test_agent, "/path/to/agent", pid)
    :ok = Agent.Registry.remove(:test_agent)

    assert Agent.Registry.lookup(:test_agent) == {:error, :not_found}
  end

  test "register overwrites existing agent" do
    pid1 = spawn(fn -> :ok end)
    pid2 = spawn(fn -> :ok end)

    Agent.Registry.register(:test_agent, "/path/1", pid1)
    Agent.Registry.register(:test_agent, "/path/2", pid2)

    assert Agent.Registry.lookup(:test_agent) == {:ok, {pid2, "/path/2"}}
  end
end

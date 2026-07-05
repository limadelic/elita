defmodule Tools.User.LookupUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()
    on_exit(fn -> :ets.delete(:agent_registry) end)
    :ok
  end

  test "lookup returns agent info when registered" do
    pid = spawn(fn -> :ok end)
    Agent.Registry.register(:dude, "/tmp/agents", pid)
    state = %{name: :test}

    {result, ^state} = Tools.User.exec("lookup", %{"name" => "dude"}, state)

    assert result == "#{inspect(pid)} at /tmp/agents"
  end

  test "lookup returns not found when unregistered" do
    state = %{name: :test}

    {result, ^state} = Tools.User.exec("lookup", %{"name" => "unknown"}, state)

    assert result == "not found"
  end

  test "spec returns tool schema" do
    state = %{name: :test}

    schema = Tools.User.spec("lookup", state)

    assert schema.name == "lookup"
    assert String.contains?(schema.description, "registry")
  end

  @tag :main
  test "lookup with empty args returns error message" do
    state = %{name: :test}

    {result, ^state} = Tools.User.exec("lookup", %{}, state)

    assert is_binary(result)
    assert String.contains?(result, "lookup")
    assert String.contains?(result, "needs")
  end
end

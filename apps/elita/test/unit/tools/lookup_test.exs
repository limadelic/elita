defmodule Tools.Sys.LookupUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()
    :ok
  end

  test "lookup returns agent info when registered" do
    pid = spawn(fn -> :ok end)
    Agent.Registry.register(:dude, "/tmp/agents", pid)
    state = %{name: :test}

    {result, ^state} = Tools.Sys.Lookup.exec("lookup", %{"name" => "dude"}, state)

    assert result == "#{inspect(pid)} at /tmp/agents"
  end

  test "lookup returns not found when unregistered" do
    state = %{name: :test}

    {result, ^state} = Tools.Sys.Lookup.exec("lookup", %{"name" => "unknown"}, state)

    assert result == "not found"
  end

  test "lookup needs name parameter" do
    state = %{name: :test}

    {result, ^state} = Tools.Sys.Lookup.exec("lookup", %{}, state)

    assert result == "lookup needs name"
  end

  test "spec returns tool schema" do
    state = %{name: :test}

    schema = Tools.Sys.Lookup.spec("lookup", state)

    assert schema.name == "lookup"
    assert String.contains?(schema.description, "registry")
    assert schema.parameters.required == ["name"]
  end
end

defmodule Tools.Sys.SpawnUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()
    :ok
  end

  @tag :main
  test "spawn registers agent in registry" do
    {response, _state} =
      Tools.Sys.Spawn.exec("spawn", %{"name" => "spawned_agent"}, %{})

    assert response == "spawned"
    assert {:ok, _} = Agent.Registry.lookup(:spawned_agent)
  end

  @tag :main
  test "spawn handles already started agent" do
    {response1, _state} =
      Tools.Sys.Spawn.exec("spawn", %{"name" => "duplicate_agent"}, %{})

    assert response1 == "spawned"

    {response2, _state} =
      Tools.Sys.Spawn.exec("spawn", %{"name" => "duplicate_agent"}, %{})

    assert response2 == "spawned"
    assert {:ok, _} = Agent.Registry.lookup(:duplicate_agent)
  end
end

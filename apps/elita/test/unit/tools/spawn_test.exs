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
end

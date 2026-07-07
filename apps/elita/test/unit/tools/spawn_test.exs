defmodule Tools.Sys.SpawnUnitTest do
  use ExUnit.Case

  setup do
    case Registry.start_link(keys: :unique, name: ElitaRegistry) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  @tag :main
  test "spawn registers agent in registry" do
    {response, _state} =
      Tools.Sys.Spawn.exec("spawn", %{"name" => "spawned_agent"}, %{})

    assert response == "spawned"
    assert [_ | _] = Registry.lookup(ElitaRegistry, "spawned_agent")
  end

  @tag :main
  test "spawn handles already started agent" do
    {response1, _state} =
      Tools.Sys.Spawn.exec("spawn", %{"name" => "duplicate_agent"}, %{})

    assert response1 == "spawned"

    {response2, _state} =
      Tools.Sys.Spawn.exec("spawn", %{"name" => "duplicate_agent"}, %{})

    assert response2 == "spawned"
    assert [_ | _] = Registry.lookup(ElitaRegistry, "duplicate_agent")
  end
end

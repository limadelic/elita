defmodule AgentsTest do
  use ExUnit.Case

  setup do
    n = "agents_test_#{:rand.uniform(999_999_999)}"

    on_exit(fn ->
      try do
        GenServer.stop({:via, Registry, {ElitaRegistry, String.downcase(n)}})
      rescue
        _ -> :ok
      catch
        :exit, _ -> :ok
      end
    end)

    {:ok, name: n}
  end

  test "exists when agent registered", %{name: n} do
    assert {:ok, _} = Elita.start_link(n, ["greet"])
    assert Agents.exists?(n)
  end

  test "missing when not registered" do
    refute Agents.exists?("no_such_agent_#{:rand.uniform(999_999_999)}")
  end
end

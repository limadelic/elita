defmodule E2E.IntercomTest do
  use ExUnit.Case, async: false

  test "doble9 auto spawns group when called" do
    result = Elita.Agent.act("doble9", "start")
    
    assert {:ok, _response} = result
    
    agents = ["doble9", "doble9_left", "doble9_top", "doble9_right", "doble9_player"]
    Enum.each(agents, fn name ->
      assert [{pid, _}] = Registry.lookup(Elita.AgentRegistry, name)
      assert is_pid(pid)
    end)
  end
end
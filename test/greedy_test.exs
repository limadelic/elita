defmodule E2E.GreedyTest do
  use ExUnit.Case, async: false

  test "greedy agent makes real decision" do
    game_state = %{
      "type" => "your_turn",
      "hand" => [[3,6], [5,7], [2,4]],
      "board" => [[6,3], [3,8]],
      "playable_ends" => [6, 8]
    }

    {:ok, response} = Elita.Agent.act("greedy", Jason.encode!(game_state))
    
    assert is_binary(response)
    assert String.contains?(response, "play") or String.contains?(response, "knock")
  end

  test "greedy agent with empty hand" do
    game_state = %{
      "type" => "your_turn", 
      "hand" => [],
      "board" => [[6,3]],
      "playable_ends" => [6, 3]
    }

    {:ok, response} = Elita.Agent.act("greedy", Jason.encode!(game_state))
    
    assert is_binary(response)
    assert String.contains?(response, "knock")
  end
end
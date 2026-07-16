defmodule TttTest do
  use Tester
  @moduletag :xunit

  setup _context do
    spawn(:alice, :ttt)
    spawn(:bob, :ttt)
    :ok
  end

  test "ttt agents play to finish" do
    tell(:bob, "alice is gonna be your opponent, wait for her move")
    tell(:alice, "start a game with bob, you are X, play first")

    await(fn -> is_game_complete?(:alice) end)

    result = ask(:alice, "tell me: did the game finish and was it a win or tie?")
    verify_completion(result)
  end

  defp is_game_complete?(agent) do
    result = ask(agent, "is the game over? answer only: yes or no")
    String.downcase(result) =~ ~r/\byes\b/
  end

  defp verify_completion(result) do
    assert result =~ "game finished"
  end
end

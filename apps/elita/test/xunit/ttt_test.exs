defmodule TttTest do
  use Tester
  @moduletag :xunit

  setup _context do
    spawn(:alice, :ttt)
    spawn(:bob, :ttt)
    :ok
  end

  test "ttt plays nine move tie" do
    tell(:bob, "alice is gonna be your opponent, wait for her move")
    tell(:alice, "start a game with bob, you are X, play first")

    await(fn -> is_game_complete?(:alice) end)

    result = ask(:alice, "tell me: did the game finish and was it a win or tie?")
    verify_tie(result)
  end

  defp is_game_complete?(agent) do
    result = ask(agent, "is the game over? answer only: yes or no")
    String.downcase(result) =~ ~r/\byes\b/
  end

  defp verify_tie(result) do
    assert String.downcase(result) =~ "tie"
  end
end

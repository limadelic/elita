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

    _completed = poll_until_complete(:alice, 120_000, 500)

    result = ask(:alice, "tell me: did the game finish and was it a win or tie?")
    verify_completion(result)
  end

  defp poll_until_complete(_agent, remaining, _interval) when remaining <= 0 do
    {:error, "timeout waiting for game to complete"}
  end

  defp poll_until_complete(agent, remaining, interval) do
    case is_game_complete?(agent) do
      true ->
        :ok

      false ->
        Process.sleep(interval)
        poll_until_complete(agent, remaining - interval, interval)
    end
  end

  defp is_game_complete?(agent) do
    result = ask(agent, "is the game over? answer only: yes or no")
    String.downcase(result) =~ ~r/\byes\b/
  end

  defp verify_completion(result) do
    assert result =~ "game finished"
  end
end

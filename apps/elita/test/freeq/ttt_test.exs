Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqTttTest do
  use FreeqCase

  @tag cassette: "ttt"
  test "ttt plays nine move tie" do
    spawn(:alice, :ttt)
    spawn(:bob, :ttt)
    tell(:bob, "alice is gonna be your opponent, wait for her move")
    tell(:alice, "start a game with bob, you are X, play first")
    assert FreeqTestClient.wait_said?("alice", "bob", "It's a tie")

    result = ask(:alice, "tell me: did the game finish and was it a win or tie?")
    verify_tie(result)

    assert FreeqTestClient.said?("alice", "bob", "Let's play tic-tac-toe")
    assert FreeqTestClient.said?("bob", "alice", "Nice opening")
    assert FreeqTestClient.said?("alice", "bob", "Good move")
    assert FreeqTestClient.said?("bob", "alice", "Smart!")
    assert FreeqTestClient.said?("alice", "bob", "position 7")
    assert FreeqTestClient.said?("bob", "alice", "Gotta block")
    assert FreeqTestClient.said?("alice", "bob", "position 4")
    assert FreeqTestClient.said?("bob", "alice", "position 6")
    assert FreeqTestClient.said?("alice", "bob", "It's a tie")
  end

  defp verify_tie(result) do
    assert String.downcase(result) =~ "tie"
  end
end

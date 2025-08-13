defmodule TttTest do
  use ElitaTester

  test "ttt agents playing each others should always tie" do
    spawn(:ttt, :alice)
    spawn(:ttt, :bob)

    tell(:bob, "alice is gonna be your opponent")
    tell(:alice, "start a game with bob, you play first")
    wait_until(:alice, "the game finish")

    verify(:alice, "tie", "what was the result?")
  end

end

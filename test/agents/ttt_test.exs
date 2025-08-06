defmodule TttTest do
  use ExUnit.Case
  import ElitaTester

  test "ttt agents playing each others should always tie" do
    start(:ttt, :alice)
    start(:ttt, :bob)

    tell(:bob, "alice is gonna be your opponent")
    tell(:alice, "start a game with bob, you play first")
    wait_until(:alice, "the game finish")

    verify(:alice, "tie", "what was the result?")
  end

end

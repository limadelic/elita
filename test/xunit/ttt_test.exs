defmodule TttTest do
  use Tester

  test "ttt agents play to finish" do
    spawn(:alice, :ttt)
    spawn(:bob, :ttt)

    tell(:bob, "alice is gonna be your opponent, wait for her move")
    tell(:alice, "start a game with bob, you are X, play first")
    wait_until(:alice, "the game finish")
  end

end

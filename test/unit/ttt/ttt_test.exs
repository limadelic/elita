defmodule TttUnitTest do
  use Tester
  @moduletag :main

  setup do
    System.put_env("CASSETTE", "ttt")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn(:alice, :ttt)
    spawn(:bob, :ttt)
    spawn(:judge)
    :ok
  end

  test "ttt agents play to finish" do
    tell(:bob, "alice is gonna be your opponent, wait for her move")
    tell(:alice, "start a game with bob, you are X, play first")

    Process.sleep(15000)

    result = ask(:alice, "tell me: did the game finish and was it a win or tie?")

    judge(result, "the game finished with a winner or a tie")
  end
end

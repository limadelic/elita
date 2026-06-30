defmodule Doble9Test do
  use Tester
  @moduletag :xunit

  setup do
    System.put_env("CASSETTE", "doble9_xunit")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn :doble9
    spawn :judge
    spawn :top, [:player, :greed]
    spawn :left, [:player, :greed]
    spawn :bottom, [:player, :greed]
    spawn :right, [:player, :greed]

    :ok
  end

  test "fresh shuffle dominoes on start" do
    ask :doble9, "start a new game with players: top, left, bottom, right"

    response = ask(:doble9, "i need 10 dominoes")
    judge(response, "the game coordinator confirms dominoes were provided")
  end

end
defmodule Doble9UnitTest do
  use Tester
  @moduletag :main

  describe "fresh shuffle" do
    setup do
      System.put_env("TAPE", "replay")
      System.put_env("CASSETTE", "doble9")

      on_exit(fn ->
        System.delete_env("TAPE")
        System.delete_env("CASSETTE")
      end)

      :ok
    end

    test "dominoes on start" do
      spawn :doble9
      spawn :top, [:player, :greed]
      spawn :left, [:player, :greed]
      spawn :bottom, [:player, :greed]
      spawn :right, [:player, :greed]

      ask :doble9, "start a new game with players: top, left, bottom, right"
      verify :doble9, "9", "i need 10 dominoes"
    end
  end
end

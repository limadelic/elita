defmodule Doble9Test do
  use Tester

  setup do
    spawn :doble9
    spawn :top, [:player, :greed]
    spawn :left, [:player, :greed]
    spawn :bottom, [:player, :greed]
    spawn :right, [:player, :greed]

    :ok
  end

  test "fresh shuffle dominoes on start" do
    ask :doble9, "start a new game with players: top, left, bottom, right"
    verify :doble9, "9", "i need 10 dominoes"
  end
end
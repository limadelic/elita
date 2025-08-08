defmodule Doble9Test do
  use ExUnit.Case
  import ElitaTester

  setup do
    start :doble9
    start :greed, :top
    start :greed, :left
    start :greed, :bottom
    start :greed, :right

    :ok
  end

  test "fresh shuffle dominoes on start" do
    ask :doble9, "start a new game with players: top, left, bottom, right"
    verify :doble9, "9", "i need 10 dominoes"
  end
end
defmodule Doble9Test do
  use ExUnit.Case
  import ElitaTester

  setup do
    start :doble9
    start :greed, :top
    start :greed, :left
    start :greed, :bottom
    start :greed, :right
    
    on_exit fn ->
      stop :doble9
      stop :top
      stop :left
      stop :bottom
      stop :right
    end
    
    :ok
  end

  test "fresh shuffle dominoes on start" do
    ask :doble9, "start a new game with players: top, left, bottom, right"
    ask :doble9, "pick dominoes"
  end
end
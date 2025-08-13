defmodule GreedTest do
  use ExUnit.Case
  import ElitaTester

  setup do
    start :greed, [ :greed, :player]
    :ok
  end

  test "greed picks highest value domino" do
    verify :greed, "[4,5]", "Table: [3,5], Dominoes: [9,9], [2,3], [9,6], [4,5]"
    verify :greed, "[1,2]", "Table: [2,5], Dominoes: [1,2], [3,6], [0,4] [7,6]"
    verify :greed, "[5,6]", "Table: [1,6], Dominoes: [2,3], [5,6]"
  end

  test "greed knocks when no moves" do
    verify :greed, "knock knock", "Table: [1,3], Dominoes: [2,4], [5,6], [0,0]"
  end
end
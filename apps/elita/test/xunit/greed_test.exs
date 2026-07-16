defmodule GreedTest do
  use Tester
  @moduletag :xunit

  setup context do
    System.put_env("CASSETTE", cassette_for(context.test))
    spawn(:greed)
    :ok
  end

  defp cassette_for(:"test greed picks highest value domino"), do: "greed"
  defp cassette_for(:"test greed knocks when no moves"), do: "greed"

  test "greed picks highest value domino" do
    verify("[4,5]", ask(:greed, "Table: [3,5], Dominoes: [9,9], [2,3], [9,6], [4,5]"))
    verify("[1,2]", ask(:greed, "Table: [2,5], Dominoes: [1,2], [3,6], [0,4] [7,6]"))
    verify("[5,6]", ask(:greed, "Table: [1,6], Dominoes: [2,3], [5,6]"))
  end

  test "greed knocks when no moves" do
    verify("knock knock", ask(:greed, "Table: [1,3], Dominoes: [2,4], [5,6], [0,0]"))
  end
end

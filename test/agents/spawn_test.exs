defmodule SpawnTest do
  use ExUnit.Case
  import ElitaTester

  setup do
    start(:mother)
    :ok
  end

  test "mother spawns baby" do
    tell(:mother, "it time to give birth")
    
    verify(:baby, "cry", "spank")
  end
end
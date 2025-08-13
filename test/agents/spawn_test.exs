defmodule SpawnTest do
  use ExUnit.Case
  import ElitaTester

  setup do
    start(:mother)
    :ok
  end

  test "mother spawns baby" do
    ask(:mother, "it time to give birth")
    
    verify(:baby, "WAAAAAH", "spank")
  end
end
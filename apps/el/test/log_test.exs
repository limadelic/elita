defmodule El.LogTest do
  use ExUnit.Case

  test "setup creates log directory and returns path" do
    path = El.Log.setup("test")
    assert String.match?(path, ~r/\.elita.*sessions.*test_\d+\.log/)
  end
end

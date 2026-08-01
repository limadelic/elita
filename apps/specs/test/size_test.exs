defmodule SizeTest do
  use SpecHelper

  test "size returns valid terminal dimensions" do
    {rows, cols} = El.Commands.Size.size()

    assert rows > 0
    assert cols > 0
    assert rows <= 300
    assert cols <= 300
  end
end

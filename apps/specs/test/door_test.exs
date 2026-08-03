defmodule DoorTest do
  use SpecHelper

  test "malko answers arithmetic through el" do
    spawn(:malko)
    result = ask("malko", "1 + 1")
    assert result =~ "2"
  end
end

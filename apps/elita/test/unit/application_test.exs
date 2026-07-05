defmodule ApplicationUnitTest do
  use Tester
  @moduletag :main

  test "el agent is alive after application starts" do
    spawned([:el])
  end
end

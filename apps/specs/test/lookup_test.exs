defmodule LookupTest do
  use SpecHelper

  test "lookup command finds a spawned native agent" do
    spawn(:greet)

    result = lookup(:greet, "hello")

    verify("who am i talking to", result)
  end
end

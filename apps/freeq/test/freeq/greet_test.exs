Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqGreetTest do
  use FreeqCase

  @moduletag :freeq
  @tag cassette: "greet"
  test "greet conversation flow" do
    spawn(:greet)
    line = wait_join("greet")
    assert String.contains?(line, "actor-class=agent")

    verify("who am i talking to", ask(:greet, "hello"))
    verify("wonderful to meet you", ask(:greet, "Brian"))
    verify("i am greeeet", ask(:greet, "how are you?"))
  end
end

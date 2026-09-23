Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqGreetTest do
  use FreeqCase

  @tag cassette: "greet"
  test "greet conversation flow" do
    spawn(:greet)

    verify("who am i talking to", ask(:greet, "hello"))
    verify("wonderful to meet you", ask(:greet, "Mike"))
    verify("i am greeeet", ask(:greet, "how are you?"))
  end
end

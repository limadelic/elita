Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqGreetTest do
  use FreeqCase

  @tag cassette: "greet"
  test "brian and greet have a real conversation in the lab" do
    join(:greet)

    say("greet: hello")
    hears("who am i talking to")

    Process.sleep(3000)

    say("greet: Mike")
    hears("wonderful to meet you")

    Process.sleep(3000)

    say("greet: how are you?")
    hears("i am greeeet")
  end
end

Code.require_file("../support/freeq_case.exs", __DIR__)
Code.require_file("../support/freeq_client.exs", __DIR__)

defmodule FreeqGreetTest do
  use FreeqCase

  @tag cassette: "greet"
  test "brian and greet have a real conversation in the lab" do
    join :greet

    say "greet: hello"
    hears "who am i talking to"

    say "greet: Mike"
    hears "wonderful to meet you"

    say "greet: how are you?"
    hears "i am greeeet"
  end
end

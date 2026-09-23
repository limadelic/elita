Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqClockTest do
  use FreeqCase

  @tag cassette: "clock"
  test "clock tells the time" do
    join(:clock)

    say("clock: what time is it")
    hears("2025-07-07 10:00")
  end
end

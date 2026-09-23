Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqClockTest do
  use FreeqCase

  @tag cassette: "clock"
  test "clock tells the time" do
    spawn(:clock)

    verify("2025-07-07 10:00", ask(:clock, "what time is it"))
  end
end

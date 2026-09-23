Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqClockTest do
  use FreeqCase

  @tag cassette: "clock"
  test "clock tells the time" do
    Tester.spawn(:clock)

    {:ok, clock_pid} =
      Elita.Freeq.start_link(
        agent: "clock",
        channel: "#the-lab",
        driver: "brian"
      )

    FreeqTestClient.wait_join("clock")

    FreeqTestClient.send_turn("clock: what time is it")
    FreeqTestClient.wait_fragment("2025-07-07 10:00")

    GenServer.stop(clock_pid)
  end
end

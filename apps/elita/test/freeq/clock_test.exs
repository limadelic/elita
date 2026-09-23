Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqClockTest do
  use FreeqCase

  @tag cassette: "clock"
  test "clock tells the time", %{socket: socket, counter: counter} do
    Tester.spawn(:clock)

    {:ok, clock_pid} =
      Elita.Freeq.start_link(
        agent: "clock",
        channel: "#the-lab",
        driver: "brian"
      )

    FreeqTestClient.wait_join(socket, "clock", counter)

    FreeqTestClient.send_turn(socket, "#the-lab", "clock: what time is it", counter)
    FreeqTestClient.wait_fragment(socket, "2025-07-07 10:00", counter)

    GenServer.stop(clock_pid)
  end
end

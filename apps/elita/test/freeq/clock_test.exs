defmodule FreeqClockTest do
  use Tester

  Code.require_file("../support/server.exs", __DIR__)
  Code.require_file("../support/freeq_client.exs", __DIR__)

  @tag cassette: "clock"
  test "clock tells the time" do
    Server.wait(~c"127.0.0.1", 6667)
    {:ok, socket} = FreeqTestClient.connect()
    {:ok, counter} = Agent.start_link(fn -> 1 end)

    Tester.spawn(:clock)

    FreeqTestClient.register_brian(socket, counter)

    {:ok, clock_pid} =
      Elita.Freeq.start_link(
        agent: "clock",
        channel: "#the-lab",
        driver: "brian"
      )

    FreeqTestClient.wait_join(socket, "clock", counter)

    FreeqTestClient.send_turn(socket, "#the-lab", "clock: what time is it", counter)
    FreeqTestClient.wait_fragment(socket, "2025-07-07 10:00", counter)

    :gen_tcp.close(socket)
    GenServer.stop(clock_pid)
  end
end

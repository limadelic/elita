Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqGreetTest do
  use FreeqCase

  @tag cassette: "greet"
  test "brian and greet have a real conversation in the lab", %{socket: socket, counter: counter} do
    Tester.spawn("greet")

    {:ok, greet_pid} =
      Elita.Freeq.start_link(
        agent: "greet",
        channel: "#the-lab",
        driver: "brian"
      )

    FreeqTestClient.wait_join(socket, "greet", counter)

    FreeqTestClient.send_turn(socket, "#the-lab", "greet: hello", counter)
    FreeqTestClient.wait_fragment(socket, "who am i talking to", counter)

    Process.sleep(3000)

    FreeqTestClient.send_turn(socket, "#the-lab", "greet: Mike", counter)
    FreeqTestClient.wait_fragment(socket, "wonderful to meet you", counter)

    Process.sleep(3000)

    FreeqTestClient.send_turn(socket, "#the-lab", "greet: how are you?", counter)
    FreeqTestClient.wait_fragment(socket, "i am greeeet", counter)

    GenServer.stop(greet_pid)
  end
end

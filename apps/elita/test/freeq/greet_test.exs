Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqGreetTest do
  use FreeqCase

  @tag cassette: "greet"
  test "brian and greet have a real conversation in the lab" do
    Tester.spawn("greet")

    {:ok, greet_pid} =
      Elita.Freeq.start_link(
        agent: "greet",
        channel: "#the-lab",
        driver: "brian"
      )

    FreeqTestClient.wait_join("greet")

    FreeqTestClient.send_turn("greet: hello")
    FreeqTestClient.wait_fragment("who am i talking to")

    Process.sleep(3000)

    FreeqTestClient.send_turn("greet: Mike")
    FreeqTestClient.wait_fragment("wonderful to meet you")

    Process.sleep(3000)

    FreeqTestClient.send_turn("greet: how are you?")
    FreeqTestClient.wait_fragment("i am greeeet")

    GenServer.stop(greet_pid)
  end
end

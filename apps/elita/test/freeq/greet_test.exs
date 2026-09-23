defmodule FreeqGreetTest do
  use Tester

  Code.require_file("../support/server.exs", __DIR__)
  Code.require_file("../support/freeq_client.exs", __DIR__)

  @tag cassette: "greet"
  test "brian and greet have a real conversation in the lab" do
    Server.wait(~c"127.0.0.1", 6667)
    {:ok, socket} = FreeqTestClient.connect()
    {:ok, counter} = Agent.start_link(fn -> 1 end)

    Tester.spawn("greet")

    FreeqTestClient.register_brian(socket, counter)

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

    :gen_tcp.close(socket)
    GenServer.stop(greet_pid)
  end
end

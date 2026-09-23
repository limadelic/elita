defmodule FreeqBossTest do
  use Tester

  Code.require_file("../support/server.exs", __DIR__)
  Code.require_file("../support/freeq_client.exs", __DIR__)

  @tag cassette: "boss"
  test "boss delegates in the lab" do
    Server.wait(~c"127.0.0.1", 6667)
    {:ok, socket} = FreeqTestClient.connect()
    {:ok, counter} = Agent.start_link(fn -> 1 end)

    Tester.spawn(:boss)
    Tester.spawn(:dev, :worker)
    Tester.spawn(:qa, :worker)

    FreeqTestClient.register_brian(socket, counter)

    {:ok, boss_pid} = Elita.Freeq.start_link(agent: "boss", channel: "#the-lab", driver: "brian")
    {:ok, dev_pid} = Elita.Freeq.start_link(agent: "dev", channel: "#the-lab", driver: "brian")
    {:ok, qa_pid} = Elita.Freeq.start_link(agent: "qa", channel: "#the-lab", driver: "brian")

    FreeqTestClient.wait_join(socket, "boss", counter)
    FreeqTestClient.wait_join(socket, "dev", counter)
    FreeqTestClient.wait_join(socket, "qa", counter)

    FreeqTestClient.send_turn(
      socket,
      "#the-lab",
      "boss: you manage a software development team with a dev and a qa",
      counter
    )

    FreeqTestClient.wait_fragment(socket, "ready", counter)

    FreeqTestClient.send_turn(socket, "#the-lab", "boss: we need more test created", counter)
    FreeqTestClient.wait_fragment(socket, "done", counter)

    FreeqTestClient.send_turn(socket, "#the-lab", "dev: did you receive a task from boss?", counter)
    FreeqTestClient.wait_fragment(socket, "no", counter)

    FreeqTestClient.send_turn(socket, "#the-lab", "qa: did you receive a task from boss?", counter)
    FreeqTestClient.wait_fragment(socket, "yes", counter)

    :gen_tcp.close(socket)
    GenServer.stop(boss_pid)
    GenServer.stop(dev_pid)
    GenServer.stop(qa_pid)
  end
end

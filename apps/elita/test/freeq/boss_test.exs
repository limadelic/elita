Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqBossTest do
  use FreeqCase

  @tag cassette: "boss"
  test "boss delegates in the lab", %{socket: socket, counter: counter} do
    Tester.spawn(:boss)
    Tester.spawn(:dev, :worker)
    Tester.spawn(:qa, :worker)

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

    FreeqTestClient.send_turn(
      socket,
      "#the-lab",
      "dev: did you receive a task from boss?",
      counter
    )

    FreeqTestClient.wait_fragment(socket, "no", counter)

    FreeqTestClient.send_turn(
      socket,
      "#the-lab",
      "qa: did you receive a task from boss?",
      counter
    )

    FreeqTestClient.wait_fragment(socket, "yes", counter)

    GenServer.stop(boss_pid)
    GenServer.stop(dev_pid)
    GenServer.stop(qa_pid)
  end

  @tag cassette: "boss2"
  test "michael asks dwight to photocopy sales reports", %{socket: socket, counter: counter} do
    Tester.spawn(:michael, :boss)
    Tester.spawn(:dwight, :boss)
    Tester.spawn(:pam, :worker)
    Tester.spawn(:jim, :worker)

    {:ok, michael_pid} =
      Elita.Freeq.start_link(agent: "michael", channel: "#the-lab", driver: "brian")

    {:ok, dwight_pid} =
      Elita.Freeq.start_link(agent: "dwight", channel: "#the-lab", driver: "brian")

    {:ok, pam_pid} = Elita.Freeq.start_link(agent: "pam", channel: "#the-lab", driver: "brian")
    {:ok, jim_pid} = Elita.Freeq.start_link(agent: "jim", channel: "#the-lab", driver: "brian")

    FreeqTestClient.wait_join(socket, "michael", counter)
    FreeqTestClient.wait_join(socket, "dwight", counter)
    FreeqTestClient.wait_join(socket, "pam", counter)
    FreeqTestClient.wait_join(socket, "jim", counter)

    FreeqTestClient.send_turn(
      socket,
      "#the-lab",
      "michael: you manage dwight the assistant regional manager",
      counter
    )

    FreeqTestClient.wait_fragment(socket, "understand", counter)

    FreeqTestClient.send_turn(
      socket,
      "#the-lab",
      "dwight: you manage pam the receptionist and jim the salesman",
      counter
    )

    FreeqTestClient.wait_fragment(socket, "understand", counter)

    FreeqTestClient.send_turn(
      socket,
      "#the-lab",
      "michael: we need 50 copies of the quarterly sales report",
      counter
    )

    FreeqTestClient.wait_fragment(socket, "done", counter)

    FreeqTestClient.send_turn(socket, "#the-lab", "jim: did you receive a task?", counter)

    FreeqTestClient.wait_fragment(socket, "no", counter)

    FreeqTestClient.send_turn(
      socket,
      "#the-lab",
      "pam: did you receive a task to make copies?",
      counter
    )

    FreeqTestClient.wait_fragment(socket, "yes", counter)

    GenServer.stop(michael_pid)
    GenServer.stop(dwight_pid)
    GenServer.stop(pam_pid)
    GenServer.stop(jim_pid)
  end
end

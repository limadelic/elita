Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqBossTest do
  use FreeqCase

  @tag cassette: "boss"
  test "boss delegates in the lab" do
    Tester.spawn(:boss)
    Tester.spawn(:dev, :worker)
    Tester.spawn(:qa, :worker)

    {:ok, boss_pid} = Elita.Freeq.start_link(agent: "boss", channel: "#the-lab", driver: "brian")
    {:ok, dev_pid} = Elita.Freeq.start_link(agent: "dev", channel: "#the-lab", driver: "brian")
    {:ok, qa_pid} = Elita.Freeq.start_link(agent: "qa", channel: "#the-lab", driver: "brian")

    FreeqTestClient.wait_join("boss")
    FreeqTestClient.wait_join("dev")
    FreeqTestClient.wait_join("qa")

    FreeqTestClient.send_turn("boss: you manage a software development team with a dev and a qa")

    FreeqTestClient.wait_fragment("ready")

    FreeqTestClient.send_turn("boss: we need more test created")
    FreeqTestClient.wait_fragment("done")

    FreeqTestClient.send_turn("dev: did you receive a task from boss?")

    FreeqTestClient.wait_fragment("no")

    FreeqTestClient.send_turn("qa: did you receive a task from boss?")

    FreeqTestClient.wait_fragment("yes")

    GenServer.stop(boss_pid)
    GenServer.stop(dev_pid)
    GenServer.stop(qa_pid)
  end

  @tag cassette: "boss2"
  test "michael asks dwight to photocopy sales reports" do
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

    FreeqTestClient.wait_join("michael")
    FreeqTestClient.wait_join("dwight")
    FreeqTestClient.wait_join("pam")
    FreeqTestClient.wait_join("jim")

    FreeqTestClient.send_turn("michael: you manage dwight the assistant regional manager")

    FreeqTestClient.wait_fragment("understand")

    FreeqTestClient.send_turn("dwight: you manage pam the receptionist and jim the salesman")

    FreeqTestClient.wait_fragment("understand")

    FreeqTestClient.send_turn("michael: we need 50 copies of the quarterly sales report")

    FreeqTestClient.wait_fragment("done")

    FreeqTestClient.send_turn("jim: did you receive a task?")

    FreeqTestClient.wait_fragment("no")

    FreeqTestClient.send_turn("pam: did you receive a task to make copies?")

    FreeqTestClient.wait_fragment("yes")

    GenServer.stop(michael_pid)
    GenServer.stop(dwight_pid)
    GenServer.stop(pam_pid)
    GenServer.stop(jim_pid)
  end
end

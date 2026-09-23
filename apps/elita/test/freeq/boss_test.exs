Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqBossTest do
  use FreeqCase

  @tag cassette: "boss"
  test "boss delegates in the lab" do
    join(:boss)
    join(:dev, :worker)
    join(:qa, :worker)

    FreeqTestClient.send_turn("boss: you manage a software development team with a dev and a qa")

    FreeqTestClient.wait_fragment("ready")

    FreeqTestClient.send_turn("boss: we need more test created")
    FreeqTestClient.wait_fragment("done")

    FreeqTestClient.send_turn("dev: did you receive a task from boss?")

    FreeqTestClient.wait_fragment("no")

    FreeqTestClient.send_turn("qa: did you receive a task from boss?")

    FreeqTestClient.wait_fragment("yes")
  end

  @tag cassette: "boss2"
  test "michael asks dwight to photocopy sales reports" do
    join(:michael, :boss)
    join(:dwight, :boss)
    join(:pam, :worker)
    join(:jim, :worker)

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
  end
end

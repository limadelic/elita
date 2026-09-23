Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqBossTest do
  use FreeqCase

  @tag cassette: "boss"
  test "boss delegates in the lab" do
    join :boss
    join :dev, :worker
    join :qa, :worker

    say "boss: you manage a software development team with a dev and a qa"

    hears "ready"

    say "boss: we need more test created"
    hears "done"

    say "dev: did you receive a task from boss?"

    hears "no"

    say "qa: did you receive a task from boss?"

    hears "yes"
  end

  @tag cassette: "boss2"
  test "michael asks dwight to photocopy sales reports" do
    join :michael, :boss
    join :dwight, :boss
    join :pam, :worker
    join :jim, :worker

    say "michael: you manage dwight the assistant regional manager"

    hears "understand"

    say "dwight: you manage pam the receptionist and jim the salesman"

    hears "understand"

    say "michael: we need 50 copies of the quarterly sales report"

    hears "done"

    say "jim: did you receive a task?"

    hears "no"

    say "pam: did you receive a task to make copies?"

    hears "yes"
  end
end

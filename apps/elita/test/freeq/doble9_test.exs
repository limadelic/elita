Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqDoble9Test do
  use FreeqCase

  @tag cassette: "doble9"
  test "doble9 deals a new game in the room" do
    spawn(:doble9)
    spawn(:top, :greed)
    spawn(:left, :greed)
    spawn(:bottom, :greed)
    spawn(:right, :greed)

    verify("dar agua", ask(:doble9, "start a new game with players: top, left, bottom, right"))
    response = ask(:doble9, "i need 10 dominoes")
    verify("10 dominoes", response)
    verify("[1,4]", response)
    verify("[9,9]", response)

    assert FreeqTestClient.wait_said?("doble9", "top", "Game is ready to start")
    assert FreeqTestClient.said?("doble9", "left", "Game is ready to start")
    assert FreeqTestClient.said?("doble9", "bottom", "Game is ready to start")
    assert FreeqTestClient.said?("doble9", "right", "Game is ready to start")
  end
end

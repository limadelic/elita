defmodule Doble9Test do
  use Tester
  @moduletag :xunit

  setup _context do
    spawn(:doble9)
    spawn(:top, [:player, :greed])
    spawn(:left, [:player, :greed])
    spawn(:bottom, [:player, :greed])
    spawn(:right, [:player, :greed])
    :ok
  end

  test "dominoes on start" do
    verify("dar agua", ask(:doble9, "start a new game with players: top, left, bottom, right"))
    response = ask(:doble9, "i need 10 dominoes")
    verify("10 dominoes", response)
    verify("[1,4]", response)
    verify("[9,9]", response)
  end
end

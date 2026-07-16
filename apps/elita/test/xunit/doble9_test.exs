defmodule Doble9Test do
  use Tester
  @moduletag :xunit

  setup context do
    System.put_env("CASSETTE", cassette_for(context.test))
    spawn(:doble9)
    spawn(:top, [:player, :greed])
    spawn(:left, [:player, :greed])
    spawn(:bottom, [:player, :greed])
    spawn(:right, [:player, :greed])
    :ok
  end

  defp cassette_for(:"test dominoes on start"), do: "doble9"

  test "dominoes on start" do
    ask(:doble9, "start a new game with players: top, left, bottom, right")
    verify("9", ask(:doble9, "i need 10 dominoes"))
  end
end

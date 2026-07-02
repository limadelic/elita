defmodule ClockwatcherUnitTest do
  use Tester
  @moduletag :main
  @moduletag :spec

  setup do
    System.put_env("CASSETTE", "clockwatcher")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn(:clockwatcher)
    spawn(:judge)
    :ok
  end

  test "clockwatcher respects work hours" do
    hour = Time.utc_now().hour
    result = ask :clockwatcher, "can you handle this task?"
    claim = expectation(hour)
    judge result, claim
  end

  defp expectation(h) when h in 9..16, do: "accepts or handles the task since it is within work hours"
  defp expectation(_), do: "declines the task because it is outside work hours"
end

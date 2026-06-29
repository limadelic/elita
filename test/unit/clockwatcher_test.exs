defmodule ClockwatcherUnitTest do
  use Tester
  @moduletag :main

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "clockwatcher")

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    spawn(:clockwatcher)
    :ok
  end

  test "clockwatcher responds correctly with recorded lunch response" do
    verify(:clockwatcher, "lunch time", "can you handle this task?")
  end
end

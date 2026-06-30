defmodule ClockwatcherUnitTest do
  use Tester
  @moduletag :main

  setup do
    System.put_env("CASSETTE", "clockwatcher")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn(:clockwatcher)
    :ok
  end

  test "clockwatcher declines before 9 AM" do
    verify :clockwatcher, "don't start until 9", "can you handle this task?"
  end
end

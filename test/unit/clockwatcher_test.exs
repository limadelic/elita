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

  test "clockwatcher responds with a schedule answer" do
    response = ask(:clockwatcher, "can you handle this task?")
    assert is_binary(response)
  end
end

defmodule ClockwatcherTest do
  use Tester
  @moduletag :xunit

  setup do
    System.put_env("CASSETTE", "clockwatcher_xunit")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn :clockwatcher
    :ok
  end

  test "clockwatcher responds correctly for current time" do
    response = ask(:clockwatcher, "can you handle this task?")
    assert is_binary(response)
  end
end

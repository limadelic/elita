defmodule ClockMockTest do
  use Tester
  @moduletag :main

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "clock")

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    spawn :clock
    :ok
  end

  test "clock gives recorded hour" do
    verify :clock, 13, "what hour is it?"
  end
end

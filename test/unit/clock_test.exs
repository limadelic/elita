defmodule ClockUnitTest do
  use Tester
  @moduletag :main
  @moduletag :spec

  setup do
    System.put_env("CASSETTE", "clock")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn :clock
    :ok
  end

  test "clock responds with an hour" do
    verify :clock, "00", "what hour is it?"
  end
end

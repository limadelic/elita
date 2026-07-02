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
    spawn :judge
    :ok
  end

  test "clock responds with an hour" do
    hour = Time.utc_now().hour
    result = ask :clock, "what hour is it?"
    judge result, "states the current hour as #{hour} UTC, or within one hour of it, possibly expressed in another timezone"
  end
end

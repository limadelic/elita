defmodule ClockUnitTest do
  use Tester
  @moduletag :main

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
    response = ask(:clock, "what hour is it?")
    assert is_binary(response)
    assert String.match?(response, ~r/\d+/)
  end
end

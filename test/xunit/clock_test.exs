defmodule ClockTest do
  use Tester
  @moduletag :xunit

  setup do
    System.put_env("CASSETTE", "clock_xunit")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn :clock
    :ok
  end

  test "clock gives current hour" do
    response = ask(:clock, "what hour is it?")
    assert is_binary(response)
    assert String.match?(response, ~r/\d+/)
  end
end
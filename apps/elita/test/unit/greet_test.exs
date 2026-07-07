defmodule GreetUnitTest do
  use Tester

  @moduletag :main
  @moduletag :spec

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "greet")

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    spawn(:greet)
    :ok
  end

  test "greet conversation flow with recorded responses" do
    verify(:greet, "Who am I talking to", "hello")
    verify(:greet, "Mike", "Mike")
    verify(:greet, "I am Greeeet", "how are you?")
  end
end

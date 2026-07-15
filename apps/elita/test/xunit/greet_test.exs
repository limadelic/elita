defmodule GreetTest do
  use Tester
  @moduletag :xunit

  setup do
    System.put_env("CASSETTE", "greet_xunit")

    on_exit(fn ->
      System.delete_env("CASSETTE")
    end)

    spawn(:greet)
    spawn(:judge)
    :ok
  end

  test "greet conversation flow" do
    greeting = ask(:greet, "hello")
    judge(greeting, "the greeter asks a question to identify who they are talking to")

    acknowledgment = ask(:greet, "Mike")
    judge(acknowledgment, "the greeter acknowledges and uses the name Mike")

    introduction = ask(:greet, "how are you?")
    judge(introduction, "the greeter identifies itself as Greeeet")
  end
end

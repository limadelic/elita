defmodule GreetTest do
  use Tester
  @moduletag :xunit

  test "greet conversation flow" do
    spawn(:greet)
    spawn(:judge)

    judge(ask(:greet, "hello"), "asks who they are talking to")
    judge(ask(:greet, "Mike"), "greets Mike by name")
    judge(ask(:greet, "how are you?"), "identifies as Greeeet")
  end
end

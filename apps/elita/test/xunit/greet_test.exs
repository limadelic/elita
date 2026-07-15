defmodule GreetTest do
  use Tester
  @moduletag :xunit

  test "greet conversation flow" do
    spawn(:greet)

    verify("asks who they are talking to", ask(:greet, "hello"))
    verify("greets Mike by name", ask(:greet, "Mike"))
    verify("identifies as Greeeet", ask(:greet, "how are you?"))
  end
end

defmodule GreetTest do
  use Tester
  @moduletag :xunit

  test "greet conversation flow" do
    spawn(:greet)

    verify("who am i talking to", ask(:greet, "hello"))
    verify("wonderful to meet you", ask(:greet, "Mike"))
    verify("i am greeeet", ask(:greet, "how are you?"))
  end
end

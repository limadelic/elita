defmodule GreetTest do
  use Tester
  @moduletag :xunit

  test "greet" do
    spawn(:greet)

    verify("who am i talking to", ask(:greet, "hello"))
    verify("wonderful to meet you", ask(:greet, "Brian"))
    verify("i am greeeet", ask(:greet, "how are you?"))
  end
end

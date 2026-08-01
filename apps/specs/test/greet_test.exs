defmodule GreetTest do
  use SpecHelper

  test "greet conversation through el" do
    spawn(:greet)

    verify("who am i talking to", ask(:greet, "hello"))
    verify("wonderful to meet you", ask(:greet, "Mike"))
    verify("i am greeeet", ask(:greet, "how are you?"))
  end
end

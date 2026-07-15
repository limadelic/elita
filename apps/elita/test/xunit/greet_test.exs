defmodule GreetTest do
  use Tester
  @moduletag :xunit

  test "greet conversation flow" do
    spawn(:greet)
    spawn(:judge)

    judge ask(:greet, "hello"), "the greeter asks a question to identify who they are talking to"
    judge ask(:greet, "Mike"), "the greeter acknowledges and uses the name Mike"
    judge ask(:greet, "how are you?"), "the greeter identifies itself as Greeeet"
  end
end

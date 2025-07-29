defmodule GreetTest do
  use ExUnit.Case
  import ElitaTester

  test "greet conversation flow" do
    pid = start(:greet)
    
    verify(pid, "hello", ["Greeeet", "Who am I talking to"])
    verify(pid, "Mike", ["Mike"])
    verify(pid, "how are you?", ["I am Greeeet"])
  end
end
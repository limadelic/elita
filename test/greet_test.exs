defmodule GreetTest do
  use ExUnit.Case
  import ElitaTester

  test "greet conversation flow" do
    start :greet
    
    verify :greet, "hello", ["Greeeet", "Who am I talking to"]
    verify :greet, "Mike", "Mike"
    verify :greet, "how are you?", "I am Greeeet"
  end
end
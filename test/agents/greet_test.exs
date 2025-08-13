defmodule GreetTest do
  use ExUnit.Case
  import Kernel, except: [spawn: 1, spawn: 2]
  import ElitaTester

  test "greet conversation flow" do
    spawn :greet
    
    verify :greet, "Who am I talking to", "hello"
    verify :greet, "Mike", "Mike"
    verify :greet, "I am Greeeet", "how are you?"
  end
end
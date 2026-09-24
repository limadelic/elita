defmodule Freeq.GreetTest do
  use Tester

  @moduletag :freeq

  import Tester, except: [spawn: 1, ask: 2]
  import Freeq, only: [spawn: 1, ask: 2]
  import Brian

  brian "greet" do
    spawn(:greet)
    verify("who am i talking to", ask(:greet, "hello"))
    verify("wonderful to meet you", ask(:greet, "Mike"))
    verify("i am greeeet", ask(:greet, "how are you?"))
  end
end

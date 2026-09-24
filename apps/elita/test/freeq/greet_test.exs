defmodule Freeq.GreetTest do
  use Tester

  @moduletag :freeq

  import Tester, except: [spawn: 1, ask: 2]
  import Freeq, only: [spawn: 1]
  import Brian

  brian "greet" do
    spawn(:greet)
    pause()
    watch(room, :greet, "#the-lab")
  end
end

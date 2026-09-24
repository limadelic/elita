defmodule Freeq.BossTest do
  use Tester

  @moduletag :freeq

  import Tester, except: [spawn: 1, spawn: 2, ask: 2, tell: 2]
  import Freeq, only: [spawn: 1, spawn: 2, ask: 2, tell: 2]
  import Brian

  @tag cassette: "boss"
  brian "boss" do
    spawn(:boss)
    spawn(:dev, :worker)
    spawn(:qa, :worker)
    tell(:boss, "you manage a software development team with a dev and a qa")
    reply = ask(:boss, "we need more test created")
    verify("done", reply)
    verify("no", ask(:dev, "did you receive a task from boss?"))
    verify("yes", ask(:qa, "did you receive a task from boss?"))
  end
end

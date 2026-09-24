defmodule Freeq.BossTest do
  use Tester

  @moduletag :freeq

  import Tester, except: [spawn: 1, spawn: 2, ask: 2]
  import Freeq, only: [spawn: 1, spawn: 2, ask: 2]
  import Brian

  @tag cassette: "boss"
  brian "boss" do
    spawn(:boss)
    spawn(:dev, :worker)
    spawn(:qa, :worker)
    verify("done", ask(:boss, "we need more test created"))
    verify("no", ask(:dev, "did you receive a task from boss?"))
    verify("yes", ask(:qa, "did you receive a task from boss?"))
  end
end

defmodule SpawnTest do
  use Tester
  @moduletag :xunit

  @tag cassette: "boss"
  test "spawn creates agents that route messages" do
    spawn(:boss)
    spawn(:dev, :worker)
    spawn(:qa, :worker)
    tell(:boss, "you manage a software development team with a dev and a qa")
    tell(:boss, "we need more test created")
    verify("no", ask(:dev, "did you receive a task from boss?"))
    verify("yes", ask(:qa, "did you receive a task from boss?"))
  end

  @tag cassette: "boss"
  test "routing multi-word msg to named agent hits agent" do
    spawn(:boss)
    spawn(:dev, :worker)
    msg = "did you receive a task from boss?"
    verify("no", ask(:dev, msg))
  end
end

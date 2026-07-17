defmodule BossTest do
  use Tester
  @moduletag :xunit

  @tag cassette: "boss"
  test "boss delegates task to worker" do
    spawn(:boss)
    spawn(:dev, :worker)
    spawn(:qa, :worker)
    tell(:boss, "you manage a software development team with a dev and a qa")
    verify("done", ask(:boss, "we need more test created"))
    verify("no", ask(:dev, "did you receive a task from boss?"))
    verify("yes", ask(:qa, "did you receive a task from boss?"))
  end

  @tag cassette: "boss2"
  test "michael asks dwight to photocopy sales reports" do
    spawn(:michael, :boss)
    spawn(:dwight, :boss)
    spawn(:pam, :worker)
    spawn(:jim, :worker)
    tell(:michael, "you manage dwight the assistant regional manager")
    tell(:dwight, "you manage pam the receptionist and jim the salesman")
    verify("done", ask(:michael, "we need 50 copies of the quarterly sales report"))
    verify("no", ask(:jim, "did you receive a task?"))
    verify("yes", ask(:pam, "did you receive a task to make copies?"))
  end
end

defmodule BossTest do
  use Tester

  test "boss delegates task to worker" do
    spawn(:boss)
    spawn(:dev, :worker)
    spawn(:qa, :worker)

    tell(:boss, "you manage a software development team with a dev and a qa")
    verify(:boss, "done", "we need more test created")

    verify(:dev, "no", "did you receive a task from boss?")
    verify(:qa, "yes", "did you receive a task from boss?")
  end

  test "michael asks dwight to photocopy sales reports" do
    spawn(:michael, :boss)
    spawn(:dwight, :boss)
    spawn(:pam, :worker)
    spawn(:jim, :worker)

    tell(:michael, "you manage dwight the assistant regional manager")
    tell(:dwight, "you manage pam the receptionist and jim the salesman")
    
    verify(:michael, "done", "we need 50 copies of the quarterly sales report")

    wait_until(:pam, "receive a task to make 50 copies")
    
    verify(:jim, "no", "did you receive a task?")
  end

end
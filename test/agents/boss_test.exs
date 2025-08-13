defmodule BossTest do
  use ExUnit.Case
  import ElitaTester

  test "boss delegates task to worker" do
    start(:boss)
    start(:dev, :worker)
    start(:qa, :worker)

    tell(:boss, "you manage a software development team with a dev and a qa")
    verify(:boss, "done", "we need more test created")

    verify(:dev, "no", "did you receive a task from boss?")
    verify(:qa, "yes", "did you receive a task from boss?")
  end

  test "michael asks dwight to photocopy sales reports" do
    start(:michael, :boss)
    start(:dwight, :boss)
    start(:pam, :worker)
    start(:jim, :worker)

    tell(:michael, "you manage dwight the assistant regional manager")
    tell(:dwight, "you manage pam the receptionist and jim the salesman")
    
    verify(:michael, "done", "we need 50 copies of the quarterly sales report")

    wait_until(:pam, "receive a task to make 50 copies")
    
    verify(:jim, "no", "did you receive a task?")
  end

end
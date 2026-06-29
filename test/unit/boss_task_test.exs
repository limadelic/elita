defmodule BossTaskUnitTest do
  use Tester
  @moduletag :main

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "boss")

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    :ok
  end

  test "boss delegates task to worker" do
    spawn(:boss)
    spawn(:dev, :worker)
    spawn(:qa, :worker)

    tell(:boss, "you manage a software development team with a dev and a qa")
    verify(:boss, "done", "we need more test created")

    verify(:dev, "no", "did you receive a task from boss?")
    verify(:qa, "yes", "did you receive a task from boss?")
  end

end

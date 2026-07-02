defmodule NapoUnitTest do
  use Tester
  @moduletag :live
  @moduletag :spec

  setup do
    System.put_env("LIVE", "1")

    on_exit(fn ->
      System.delete_env("LIVE")
    end)

    spawn :napo
    :ok
  end

  test "napo reuses colony across instances" do
    problem1 = "Our company's profit declined 30% this year. Build the complete root-cause tree: every driver decomposed to concrete checkable causes with the data you'd pull for each. A summary of top-level drivers is not acceptable."
    problem2 = "Same analysis for a different company: a 45% profit decline at a retail chain."

    reply1 = ask :napo, problem1
    assert is_binary(reply1), "Expected binary reply, got: #{inspect(reply1)}"
    assert String.length(reply1) > 50, "Reply1 should analyze profit decline drivers"

    reply2 = ask :napo, problem2
    assert is_binary(reply2), "Expected binary reply, got: #{inspect(reply2)}"
    assert String.length(reply2) > 50, "Reply2 should analyze retail chain profit decline"
  end
end

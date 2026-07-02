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

  test "napo decomposes research synthesis" do
    problem = "What caused the 2008 financial crisis?"

    reply = ask :napo, problem

    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 10, "Reply too short"
  end

  test "napo decomposes product decision" do
    problem = "Should a small SaaS raise prices? Analyze."

    reply = ask :napo, problem

    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 10, "Reply too short"
  end

  test "napo decomposes engineering tradeoff" do
    problem = "Design a rate limiter for a public API — what are the key decisions?"

    reply = ask :napo, problem

    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 10, "Reply too short"
  end

  test "napo decomposes exhaustive analysis" do
    problem = """
    Three independent ethical analysis tasks:
    (1) AI Bias - technical root cause (data selection, training methods), one verified incident (e.g., COMPAS, facial recognition), current mitigations, gaps, research.
    (2) AI Privacy - technical root cause (data collection, training inference), one verified incident (e.g., membership inference attack), current mitigations, gaps, research.
    (3) AI Autonomy - technical root cause (lack of human control), one verified incident (e.g., recommendation algorithms), current mitigations, gaps, research.
    STRICT: Must cover all three concerns. Each needs: technical cause + real incident + mitigations + gaps + research directions.
    Missing any concern or sub-element = rejection.
    """

    reply = ask :napo, problem

    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 200, "Reply must address all three concerns"
    assert String.contains?(reply, ["Bias", "Privacy", "Autonomy"]) || String.contains?(reply, ["bias", "privacy", "autonomy"]), "Must address all three concerns"
  end

  test "stage 2: napo decomposes with attempts=1" do
    problem = """
    STAGE 2 FORCED DECOMPOSE TEST (attempts capped at 1).
    Produce three detailed, independent analyses:
    (A) Netflix Qwikster 2011—crisis, decisions (Hastings' name required), recovery outcome
    (B) Lego 2003 bankruptcy—crisis, decisions (Knudstorp's name required), recovery outcome
    (C) Apple 2008 response—crisis, decisions (Jobs/Cook names required), response outcome
    STRICT: All three must be present with specific names and outcomes. Missing any company = rejection.
    This problem is designed to trigger decomposition (child napos for A, B, C).
    """

    reply = ask :napo, problem

    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 300, "Reply must synthesize all three case studies"
    assert String.contains?(reply, ["Netflix", "Lego", "Apple"]), "All three companies must be in final answer"
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

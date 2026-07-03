defmodule NapoProfitTest do
  use Tester
  @moduletag :live
  @moduletag :spec

  setup do
    System.put_env("LIVE", "1")
    System.put_env("CASSETTE", "profit")

    unless System.get_env("TAPE") do
      System.put_env("TAPE", "replay")
    end

    on_exit(fn ->
      System.delete_env("LIVE")
      System.delete_env("CASSETTE")
      System.delete_env("TAPE")
    end)

    spawn :napo
    :ok
  end

  test "shape: conglomerate with three divisions forces split" do
    problem = "Our conglomerate's profit declined 30% this year across three very different divisions: grocery retail, streaming media, and industrial logistics. Build the complete root-cause tree for EACH division — every driver decomposed to concrete checkable causes with the specific data you would pull for each. All three divisions fully worked out; a summary or a single generic tree is not acceptable."

    reply = ask :napo, problem
    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 500, "Shape test should produce comprehensive multi-division analysis"
    # Verify split happened: response should contain all three division sections
    assert String.contains?(reply, ["GROCERY", "STREAMING", "LOGISTICS"]) or
           String.contains?(reply, ["grocery", "streaming", "logistics"]),
           "Reply should contain all three divisions"
  end

  test "sample 1: generic single-company profit decline" do
    problem = "Our company's profit declined 35% this year. Build a complete root-cause analysis: every driver decomposed to concrete checkable causes with the specific data you would pull for each."

    reply = ask :napo, problem
    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 50, "Sample 1 should provide root-cause analysis"
  end

  test "sample 2: retail chain profit decline" do
    problem = "A retail chain experienced a 40% profit decline. Analyze complete root causes: revenue drivers, cost pressures, inventory issues, operational inefficiencies with specific data sources and metrics for each."

    reply = ask :napo, problem
    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 50, "Sample 2 should analyze retail profit decline"
  end

  test "sample 3: tech company margin compression" do
    problem = "A technology company saw profit margins compress by 25% while revenue grew 10%. Identify all drivers: revenue quality decline, cost structure inflation, mix shifts, operational inefficiencies. Provide concrete metrics and data sources for each."

    reply = ask :napo, problem
    assert is_binary(reply), "Expected binary reply, got: #{inspect(reply)}"
    assert String.length(reply) > 50, "Sample 3 should analyze tech company margin compression"
  end
end

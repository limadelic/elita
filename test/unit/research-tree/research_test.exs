defmodule ResearchUnitTest do
  use Tester
  @moduletag :main
  @moduletag :prose

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "research-tree")

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    spawn(:research)
    spawn(:judge)
    :ok
  end

  test "research coordinates multiple researchers into synthesis" do
    question = "What makes a city good for remote work?"

    result = ask(:research, question)

    spawned([:researcher_1, :researcher_2, :researcher_3])

    judge(result, "synthesis includes analysis of internet infrastructure or connectivity for remote workers")
    judge(result, "synthesis includes information about cost of living or affordability for remote workers")
    judge(result, "synthesis discusses community culture or social aspects that matter to remote workers")
  end
end

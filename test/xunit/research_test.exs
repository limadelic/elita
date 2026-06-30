defmodule ResearchTest do
  use Tester
  import String, only: [contains?: 2, downcase: 1]

  @moduletag :xunit
  @moduletag :prose

  test "research coordinates multiple researchers into synthesis" do
    spawn(:research)

    question = "What makes a city good for remote work?"

    result = ask(:research, question)

    spawned([:researcher_1, :researcher_2, :researcher_3])

    # Verify synthesis includes insights from each angle
    assert contains?(downcase(result), downcase("internet")) or
           contains?(downcase(result), downcase("connectivity")) or
           contains?(downcase(result), downcase("bandwidth"))

    assert contains?(downcase(result), downcase("cost")) or
           contains?(downcase(result), downcase("affordable")) or
           contains?(downcase(result), downcase("price"))

    assert contains?(downcase(result), downcase("community")) or
           contains?(downcase(result), downcase("culture")) or
           contains?(downcase(result), downcase("lifestyle")) or
           contains?(downcase(result), downcase("social"))
  end

end

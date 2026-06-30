defmodule MaskedRelayTest do
  use Tester
  import String, only: [contains?: 2, downcase: 1]

  @moduletag :xunit
  @moduletag :prose

  test "relay routes masked views to each scout" do
    spawn(:relay)

    input = """
    {
      "price": "expensive at $99/month",
      "friction": "smooth onboarding process",
      "desire": "strong customer demand"
    }
    """

    result = ask(:relay, input)

    # Verify all agents spawned
    spawned([:relay, :scout_price, :scout_friction, :scout_desire, :auditor])

    # Verify each role's view in the final result
    assert contains?(downcase(result), downcase("price"))
    assert contains?(downcase(result), downcase("friction"))
    assert contains?(downcase(result), downcase("desire"))
    assert contains?(downcase(result), downcase("consensus"))
  end

  test "scouts are blind to sibling data" do
    spawn(:relay)

    input = """
    {
      "price": "high cost",
      "friction": "complex workflow",
      "desire": "low interest"
    }
    """

    result = ask(:relay, input)

    # All scouts spawn and report their own view only
    spawned([:relay, :scout_price, :scout_friction, :scout_desire, :auditor])

    # Result contains synthesis, not raw input
    assert contains?(downcase(result), downcase("consensus"))
  end
end

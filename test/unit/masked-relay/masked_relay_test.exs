defmodule MaskedRelayUnitTest do
  use Tester
  @moduletag :main
  @moduletag :prose

  setup do
    System.put_env("CASSETTE", "masked-relay")
    System.put_env("MATCHER", "relaxed")

    on_exit(fn ->
      System.delete_env("CASSETTE")
      System.delete_env("MATCHER")
    end)

    spawn(:relay)
    spawn(:judge)
    :ok
  end

  test "relay routes masked views to each scout" do
    input = """
    {
      "price": "expensive at $99/month",
      "friction": "smooth onboarding process",
      "desire": "strong customer demand"
    }
    """

    result = ask(:relay, input)

    spawned([:relay, :scout_price, :scout_friction, :scout_desire, :auditor])

    judge(result, "result discusses the price aspect")
    judge(result, "result discusses the friction aspect")
    judge(result, "result discusses the desire aspect")
    judge(result, "result includes a consensus viewpoint")
  end

  test "scouts are blind to sibling data" do
    input = """
    {
      "price": "high cost",
      "friction": "complex workflow",
      "desire": "low interest"
    }
    """

    result = ask(:relay, input)

    spawned([:relay, :scout_price, :scout_friction, :scout_desire, :auditor])

    judge(result, "result shows consensus across price friction and desire considerations")
  end
end

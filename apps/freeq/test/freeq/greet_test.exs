Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqGreetTest do
  use FreeqCase

  @moduletag :freeq
  @tag cassette: "greet"
  test "greet conversation flow" do
    line = spawn(:greet)
    assert String.contains?(line, "actor-class=agent")

    verify("who am i talking to", ask(:greet, "hello"))
    verify("wonderful to meet you", ask(:greet, "Brian"))
    verify("i am greeeet", ask(:greet, "how are you?"))
  end

  @tag cassette: "greet"
  test "greet survives a failed answer" do
    spawn(:greet)

    answer = ask(:greet, "hello")
    verify("who am i talking to", answer)

    answer = ask(:greet, "unknown question")
    verify("could not answer", answer)

    answer = ask(:greet, "Brian")
    verify("wonderful to meet you", answer)
  end

  @tag cassette: "greet"
  test "an agent cannot take a nick already in use" do
    start_time = System.monotonic_time(:millisecond)
    result = Freeq.Resident.start(:brian, "#the-lab", ~c"127.0.0.1", port())
    elapsed = System.monotonic_time(:millisecond) - start_time
    assert {:error, msg} = result
    assert String.contains?(msg, "nick brian in use")
    assert elapsed < 1000
  end
end

Code.require_file("../support/freeq_case.exs", __DIR__)

defmodule FreeqGreetTest do
  use FreeqCase

  import Registry, only: [lookup: 2]

  @moduletag :freeq
  @tag cassette: "greet"
  test "greet conversation flow" do
    spawn(:greet)

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
    assert agent_left?("brian")
  end

  defp agent_left?(name) do
    poll_until_gone(name, System.monotonic_time(:millisecond) + 500)
  end

  defp agent_gone?(name) do
    lookup(ElitaRegistry, name) == []
  end

  defp time_left?(deadline) do
    System.monotonic_time(:millisecond) < deadline
  end

  defp wait_again(name, deadline) do
    Process.sleep(10)
    poll_until_gone(name, deadline)
  end

  defp retry_if_time_left(name, deadline) do
    time_left?(deadline) && wait_again(name, deadline)
  end

  defp poll_until_gone(name, deadline) do
    agent_gone?(name) || retry_if_time_left(name, deadline)
  end
end

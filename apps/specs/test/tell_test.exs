defmodule TellTest do
  use SpecHelper
  import Enum, only: [any?: 2]

  @tag cassette: "greet"
  test "tell delivers message to native agent" do
    spawn(:greet)

    msg = "hello"
    Elita.dispatch(:greet, msg)
    Process.sleep(200)

    [{agent_pid, _}] = Registry.lookup(ElitaRegistry, "greet")
    state = :sys.get_state(agent_pid)

    assert any?(state.history, &received?(msg, &1))
  end

  defp received?(expected, %{role: "user", content: content}) do
    content == expected
  end

  defp received?(_expected, _), do: false
end

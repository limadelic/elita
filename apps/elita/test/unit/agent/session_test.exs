defmodule Agent.SessionUnitTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = Agent.Session.start_link(name: :test, folder: "/tmp", runner: &stub_claude/2)
    {:ok, pid: pid}
  end

  test "ask sends message and returns response", %{pid: pid} do
    {:ok, response} = Agent.Session.ask(pid, "hello")
    assert response == "stub response"
  end

  test "cast sends message without waiting for response", %{pid: pid} do
    :ok = Agent.Session.cast(pid, "hello")
  end

  defp stub_claude(_message, _folder) do
    "stub response"
  end
end

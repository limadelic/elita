defmodule Tools.User.WakeUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()
    {:ok, pid} = Agent.Session.start_link(name: :runner, folder: "/tmp", runner: &stub_runner/2)
    Agent.Registry.register(:runner, "/tmp", pid)
    :ok
  end

  @tag :main
  test "wake registered agent returns stub response" do
    {response, _state} =
      Tools.User.exec("wake", %{"agent" => "runner", "message" => "hello"}, %{})

    assert response == "stub response"
  end

  @tag :main
  test "wake unknown agent returns error string" do
    {response, _state} =
      Tools.User.exec("wake", %{"agent" => "unknown", "message" => "hello"}, %{})

    assert response == "agent not found"
  end

  defp stub_runner(_message, _folder) do
    "stub response"
  end
end

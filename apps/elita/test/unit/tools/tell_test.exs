defmodule Tools.User.TellUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()

    case Registry.start_link(keys: :unique, name: ElitaRegistry) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  @tag :main
  test "tell nil-folder agent dispatches via Elita.cast" do
    pid = spawn(fn -> :timer.sleep(:infinity) end)
    Agent.Registry.register(:local, nil, pid)

    {response, _state} =
      Tools.User.exec("tell", %{"recipient" => "local", "message" => "hello"}, %{})

    assert response == "message sent"
  end

  @tag :main
  test "tell binary-folder agent dispatches via Agent.Session.cast" do
    {:ok, pid} =
      Agent.Session.start_link(name: :worker, folder: "/tmp", runner: &stub_runner/2)

    Agent.Registry.register(:worker, "/tmp", pid)

    {response, _state} =
      Tools.User.exec("tell", %{"recipient" => "worker", "message" => "hello"}, %{})

    assert response == "message sent"
  end

  @tag :main
  test "tell unknown agent returns error string" do
    {response, _state} =
      Tools.User.exec("tell", %{"recipient" => "unknown", "message" => "hello"}, %{})

    assert response == "agent not found"
  end

  defp stub_runner(_message, _folder) do
    "stub response"
  end
end

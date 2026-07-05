defmodule Tools.User.WakeUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()
    ensure_registry_started()
    :ok
  end

  defp ensure_registry_started do
    case Registry.start_link(keys: :unique, name: ElitaRegistry) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  @tag :main
  test "wake nil-folder agent dispatches via Elita.call" do
    pid = spawn(fn -> :timer.sleep(:infinity) end)
    Agent.Registry.register(:elita_agent, nil, pid)

    result =
      try do
        Tools.User.exec("wake", %{"agent" => "elita_agent", "message" => "hello"}, %{})
      rescue
        _error -> :error_from_elita
      catch
        :exit, _reason -> :error_from_elita
      else
        res -> res
      end

    refute result == "agent not found"
  end

  @tag :main
  test "wake binary-folder agent dispatches via Agent.Session.ask" do
    {:ok, pid} =
      Agent.Session.start_link(name: :session_agent, folder: "/tmp", runner: &stub_runner/2)

    Agent.Registry.register(:session_agent, "/tmp", pid)

    {response, _state} =
      Tools.User.exec("wake", %{"agent" => "session_agent", "message" => "hello"}, %{})

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

defmodule Agent.RouterUnitTest do
  use ExUnit.Case

  setup do
    Agent.Registry.create()
    {:ok, pid} = Agent.Session.start_link(name: :dude, folder: "/tmp", runner: &stub_runner/2)
    Agent.Registry.register(:dude, "/tmp", pid)
    :ok
  end

  test "route ask to registered external agent" do
    {:ok, response} = Agent.Router.route(:dude, :ask, "hello")
    assert response == "stub response"
  end

  test "route tell to registered external agent" do
    :ok = Agent.Router.route(:dude, :tell, "hello")
  end

  test "route ask to markdown agent falls back" do
    {:ok, response} = Agent.Router.route(:greet, :ask, "hello")
    assert is_binary(response) or response == :not_found
  end

  test "route unknown agent returns error" do
    {:error, :not_found} = Agent.Router.route(:unknown, :ask, "hello")
  end

  defp stub_runner(_message, _folder) do
    "stub response"
  end
end

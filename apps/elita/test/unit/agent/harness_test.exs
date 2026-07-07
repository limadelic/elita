defmodule Agent.HarnessTest do
  use ExUnit.Case
  @moduletag :main

  test "dispatch returns error for unknown recipient" do
    result = Agent.Harness.dispatch("unknown_agent", "hello", :ask)
    assert result == "unknown: unknown_agent"
  end

  test "dispatch returns error for unknown tell recipient" do
    result = Agent.Harness.dispatch("nonexistent", "message", :tell)
    assert result == "unknown: nonexistent"
  end

  test "dispatch routes ask to puppet" do
    stub = start_stub("puppet_test", :puppet)
    result = Agent.Harness.dispatch("puppet_test", "hello", :ask)
    assert result == "hello response"
    GenServer.stop(stub)
  end

  test "dispatch routes tell to puppet" do
    stub = start_stub("puppet_tell", :puppet)
    result = Agent.Harness.dispatch("puppet_tell", "msg", :tell)
    assert result == :ok
    GenServer.stop(stub)
  end

  test "dispatch routes ask to headless session" do
    {:ok, _pid} = Agent.Session.start_link(name: :dude, folder: System.tmp_dir!())
    result = Agent.Harness.dispatch("dude", "hello", :ask)
    assert is_binary(result)
  end

  test "dispatch with uppercase in recipient" do
    stub = start_stub("TestAgent", :puppet)
    result = Agent.Harness.dispatch("TestAgent", "msg", :ask)
    assert result == "hello response"
    GenServer.stop(stub)
  end

  test "dispatch ask with nil input" do
    stub = start_stub("test_nil", :puppet)
    result = Agent.Harness.dispatch("test_nil", nil, :ask)
    assert result == "hello response"
    GenServer.stop(stub)
  end

  defp start_stub(name, kind) do
    {:ok, pid} = TestStub.start_link(name: name, kind: kind)
    pid
  end
end

defmodule TestStub do
  use GenServer
  import String, only: [downcase: 1]

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    kind = Keyword.fetch!(opts, :kind)
    normalized = name |> downcase()
    via_name = {:via, Registry, {ElitaRegistry, normalized, %{kind: kind, folder: "."}}}
    GenServer.start_link(__MODULE__, {}, name: via_name)
  end

  def init(_) do
    {:ok, {}}
  end

  def handle_call({:ask, _msg}, _from, state) do
    {:reply, {:ok, "hello response"}, state}
  end

  def handle_cast({:cast, _msg}, state) do
    {:noreply, state}
  end
end

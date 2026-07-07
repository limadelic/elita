defmodule StubAgent do
  use GenServer

  def init(state), do: {:ok, state}

  def handle_call({:act, _msg}, _from, state) do
    {:reply, "stub response", state}
  end

  def handle_cast({:inject, msg}, state) do
    Agent.update(:msg_log, &[msg | &1])
    {:noreply, state}
  end

  def handle_cast({:act, msg}, state) do
    Agent.update(:msg_log, &[msg | &1])
    {:noreply, state}
  end
end

defmodule StubRunner do
  def run(_msg, _folder), do: "stub runner response"
end

defmodule AddressTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  test "ask with address forms (bare, relative, absolute, unknown, ambiguous, file wake)" do
    # Setup: Create tmp folder structure
    base = System.tmp_dir() |> Path.join("elita_address_test_#{System.unique_integer()}")
    File.mkdir_p!(base)
    base = Path.expand(base)

    bare_folder = Path.expand(Path.join(base, "agent1"))
    sub_folder = Path.expand(Path.join(base, "sub"))
    deep_folder = Path.expand(Path.join(sub_folder, "agent2"))
    File.mkdir_p!(bare_folder)
    File.mkdir_p!(deep_folder)

    old_cwd = File.cwd!()
    File.cd!(base)

    registrations = "agent1:#{bare_folder},agent2:#{deep_folder},agent1:#{sub_folder}"
    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", registrations)

    # Start registry and create stub agents
    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    via1 = {:via, Registry, {ElitaRegistry, "agent1", %{kind: :native, folder: bare_folder}}}
    GenServer.start_link(StubAgent, "ok", name: via1)

    via2 = {:via, Registry, {ElitaRegistry, "agent2", %{kind: :native, folder: deep_folder}}}
    GenServer.start_link(StubAgent, "ok", name: via2)

    via3 = {:via, Registry, {ElitaRegistry, "agent1", %{kind: :native, folder: sub_folder}}}
    GenServer.start_link(StubAgent, "ok", name: via3)

    on_exit(fn ->
      File.cd!(old_cwd)
      System.put_env("AGENT_REGISTRATIONS", old_registrations || "")
      File.rm_rf!(base)
    end)

    # Test 1: bare name (current behavior)
    output1 = capture_io(fn -> El.Commands.Ask.execute("agent1", "msg") end)
    refute String.contains?(output1, "unknown: agent1")

    # Test 2: name@relative path
    output2 = capture_io(fn -> El.Commands.Ask.execute("agent2@sub/agent2", "msg") end)
    refute String.contains?(output2, "unknown: agent2")

    # Test 3: name@absolute path
    deep_abs = Path.join(base, "sub/agent2")
    output3 = capture_io(fn -> El.Commands.Ask.execute("agent2@#{deep_abs}", "msg") end)
    refute String.contains?(output3, "unknown: agent2")

    # Test 4: unknown address
    output4 = capture_io(fn -> El.Commands.Ask.execute("missing@/bad", "msg") end)
    assert String.contains?(output4, "unknown: missing@/bad")

    # Test 5: ambiguous address (matches multiple)
    output5 = capture_io(fn -> El.Commands.Ask.execute("agent1@/**", "msg") end)
    assert String.contains?(output5, "ask requires one target")

    # Test 6: file wake - create a file agent, no live process
    File.write!(Path.join(bare_folder, "doctor.exs"), "# stub agent file")

    # Verify the file agent is not live before ask
    assert Registry.lookup(ElitaRegistry, "doctor") == []

    # Set test runner environment variable
    old_runner = System.get_env("TEST_AGENT_RUNNER")
    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    # Call ask with stub runner to avoid spawning claude
    output6 = capture_io(fn ->
      El.Commands.Ask.execute("doctor@#{bare_folder}", "msg",
        env_module: FakeEnv)
    end)

    # Restore environment
    if old_runner do
      System.put_env("TEST_AGENT_RUNNER", old_runner)
    else
      System.delete_env("TEST_AGENT_RUNNER")
    end

    # Verify session was started
    assert Registry.lookup(ElitaRegistry, "doctor") != []

    # Verify it didn't return unknown
    refute String.contains?(output6, "unknown: doctor")

    Agent.start_link(fn -> [] end, name: :msg_log)

    capture_io(fn ->
      El.Commands.Tell.execute("agent1@/**", "broadcast msg", env_module: FakeEnv)
    end)

    sent = Agent.get(:msg_log, & &1)
    assert length(sent) == 2
  end
end

defmodule FakeEnv do
  def get(_), do: "fake_node@fake_host"
end



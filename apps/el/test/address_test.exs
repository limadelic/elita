defmodule StubAgent do
  use GenServer

  def init(state), do: {:ok, state}

  def handle_call({:act, _msg}, _from, state) do
    {:reply, "stub response", state}
  end

  def handle_cast({:inject, msg}, state) do
    Agent.update(:msg_log, &[{state, msg} | &1])
    {:noreply, state}
  end

  def handle_cast({:act, msg}, state) do
    Agent.update(:msg_log, &[{state, msg} | &1])
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

    registrations = "agent1:#{sub_folder},agent3:#{sub_folder},agent2:#{deep_folder}"
    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", registrations)

    # Start registry and create stub agents
    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    via1 = {:via, Registry, {ElitaRegistry, "agent1", %{kind: :native, folder: sub_folder}}}
    GenServer.start_link(StubAgent, "agent1", name: via1)

    via3 = {:via, Registry, {ElitaRegistry, "agent3", %{kind: :native, folder: sub_folder}}}
    GenServer.start_link(StubAgent, "agent3", name: via3)

    via2 = {:via, Registry, {ElitaRegistry, "agent2", %{kind: :native, folder: deep_folder}}}
    GenServer.start_link(StubAgent, "agent2", name: via2)

    on_exit(fn ->
      File.cd!(old_cwd)
      System.put_env("AGENT_REGISTRATIONS", old_registrations || "")
      File.rm_rf!(base)
    end)

    # Test 1: bare name (current behavior)
    output1 = capture_io(fn -> El.Commands.Ask.execute("agent1", "msg") end)
    refute String.contains?(output1, "unknown: agent1")

    # Test 2: name@relative path
    output2 = capture_io(fn -> El.Commands.Ask.execute("agent1@sub", "msg") end)
    refute String.contains?(output2, "unknown: agent1")

    # Test 3: name@absolute path
    sub_abs = Path.join(base, "sub")
    output3 = capture_io(fn -> El.Commands.Ask.execute("agent1@#{sub_abs}", "msg") end)
    refute String.contains?(output3, "unknown: agent1")

    # Test 4: unknown address
    output4 = capture_io(fn -> El.Commands.Ask.execute("missing@/bad", "msg") end)
    assert String.contains?(output4, "unknown: missing@/bad")

    # Test 5: file wake - create a file agent, no live process
    File.write!(Path.join(sub_folder, "doctor.exs"), "# stub agent file")

    # Verify the file agent is not live before ask
    assert Registry.lookup(ElitaRegistry, "doctor") == []

    # Set test runner environment variable
    old_runner = System.get_env("TEST_AGENT_RUNNER")
    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    # Call ask with stub runner to avoid spawning claude
    output6 = capture_io(fn ->
      El.Commands.Ask.execute("doctor@#{sub_folder}", "msg",
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

    sub_abs = Path.join(base, "sub")
    capture_io(fn ->
      El.Commands.Tell.execute("@#{sub_abs}", "broadcast msg", env_module: FakeEnv)
    end)

    sent = Agent.get(:msg_log, & &1)
    recipients = sent |> Enum.map(&elem(&1, 0)) |> Enum.sort()
    assert recipients == ["agent1", "agent3"]

    # Test cd command
    El.Commands.Cd.execute("sub")
    cwd_after_cd = El.Commands.Address.World.cwd()
    assert String.ends_with?(cwd_after_cd, "sub")

    output_after_cd = capture_io(fn -> El.Commands.Ls.execute() end)
    assert String.contains?(output_after_cd, "agent1")
    assert String.contains?(output_after_cd, "agent3")

    # Test cd ~ (home/birth folder)
    birth_folder = El.Standpoint.birth()
    El.Commands.Cd.execute("~")
    cwd_home = El.Commands.Address.World.cwd()
    assert cwd_home == birth_folder

    # Test cd .. (parent directory)
    El.Commands.Cd.execute("sub")
    El.Commands.Cd.execute("..")
    cwd_after_up = El.Commands.Address.World.cwd()
    assert cwd_after_up == birth_folder
  end
end

defmodule FakeEnv do
  def get(_), do: "fake_node@fake_host"
end

defmodule LsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  test "ls with path forms (bare, relative, absolute, glob)" do
    base = System.tmp_dir() |> Path.join("elita_ls_test_#{System.unique_integer()}")
    File.mkdir_p!(base)
    base = Path.expand(base)

    sub = Path.expand(Path.join(base, "sub"))
    deep = Path.expand(Path.join(sub, "deep"))
    File.mkdir_p!(deep)

    File.write!(Path.join(base, "root_agent.exs"), "# root")
    File.write!(Path.join(sub, "sub_agent.exs"), "# sub")
    File.write!(Path.join(deep, "deep_agent.exs"), "# deep")

    old_cwd = File.cwd!()
    File.cd!(base)

    registrations = "root_agent:#{base},sub_agent:#{sub},deep_agent:#{deep}"
    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", registrations)

    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    via1 = {:via, Registry, {ElitaRegistry, "root_agent", %{kind: :file, path: base}}}
    GenServer.start_link(StubAgent, "root_agent", name: via1)

    via2 = {:via, Registry, {ElitaRegistry, "sub_agent", %{kind: :file, path: sub}}}
    GenServer.start_link(StubAgent, "sub_agent", name: via2)

    on_exit(fn ->
      File.cd!(old_cwd)
      System.put_env("AGENT_REGISTRATIONS", old_registrations || "")
      File.rm_rf!(base)
    end)

    # Test 1: bare ls (current directory)
    output1 = capture_io(fn -> El.Commands.Ls.execute() end)
    assert String.contains?(output1, "root_agent")
    assert String.contains?(output1, "active")

    # Test 2: ls relative path
    output2 = capture_io(fn -> El.Commands.Ls.execute(path: "sub") end)
    assert String.contains?(output2, "sub_agent")
    assert String.contains?(output2, "active")
    refute String.contains?(output2, "root_agent")

    # Test 3: ls absolute path
    output3 = capture_io(fn -> El.Commands.Ls.execute(path: sub) end)
    assert String.contains?(output3, "sub_agent")
    refute String.contains?(output3, "root_agent")

    # Test 4: ls with glob
    output4 = capture_io(fn -> El.Commands.Ls.execute(path: "**") end)
    assert String.contains?(output4, "sub_agent")
    assert String.contains?(output4, "deep_agent")
    assert String.contains?(output4, "asleep")
  end
end


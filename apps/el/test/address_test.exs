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

  def handle_cast({:inject, msg, reply_to: {ref, caller_pid}}, state) do
    Agent.update(:msg_log, &[{state, msg} | &1])
    send(caller_pid, {ref, "immediate answer"})
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
    base =
      System.tmp_dir()
      |> Path.join("elita_address_test_#{System.unique_integer()}")

    File.mkdir_p!(base)
    base = Path.expand(base)

    bare_folder = Path.expand(Path.join(base, "agent1"))
    sub_folder = Path.expand(Path.join(base, "sub"))
    deep_folder = Path.expand(Path.join(sub_folder, "agent2"))
    File.mkdir_p!(bare_folder)
    File.mkdir_p!(deep_folder)

    old_cwd = File.cwd!()
    File.cd!(base)

    registrations =
      "agent1:#{sub_folder},agent3:#{sub_folder},agent2:#{deep_folder}"

    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", registrations)

    # Start registry and create stub agents
    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    via1 =
      {:via, Registry, {ElitaRegistry, "agent1", %{kind: :native, folder: sub_folder}}}

    GenServer.start_link(StubAgent, "agent1", name: via1)

    via3 =
      {:via, Registry, {ElitaRegistry, "agent3", %{kind: :native, folder: sub_folder}}}

    GenServer.start_link(StubAgent, "agent3", name: via3)

    via2 =
      {:via, Registry, {ElitaRegistry, "agent2", %{kind: :native, folder: deep_folder}}}

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

    output3 =
      capture_io(fn -> El.Commands.Ask.execute("agent1@#{sub_abs}", "msg") end)

    refute String.contains?(output3, "unknown: agent1")

    # Test 4: unknown address
    output4 =
      capture_io(fn -> El.Commands.Ask.execute("missing@/bad", "msg") end)

    assert String.contains?(output4, "unknown: missing@/bad")

    # Test 5: file wake - create a file agent, no live process
    File.write!(Path.join(sub_folder, "doctor.exs"), "# stub agent file")

    # Verify the file agent is not live before ask
    assert Registry.lookup(ElitaRegistry, "doctor") == []

    # Set test runner environment variable
    old_runner = System.get_env("TEST_AGENT_RUNNER")
    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    # Call ask with stub runner to avoid spawning claude
    output6 =
      capture_io(fn ->
        El.Commands.Ask.execute("doctor@#{sub_folder}", "msg", env_module: FakeEnv)
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

    # Test folder ask WITH agent.md
    folder_with_md = Path.join(base, "crew")
    File.mkdir_p!(folder_with_md)
    agent_md = Path.join(folder_with_md, "agent.md")
    File.write!(agent_md, "# crew agent\nI am a crew receptionist")

    registrations =
      registrations <> ",crew:#{folder_with_md}"

    System.put_env("AGENT_REGISTRATIONS", registrations)

    old_runner = System.get_env("TEST_AGENT_RUNNER")
    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    output_crew =
      capture_io(fn ->
        El.Commands.Ask.execute("crew@#{folder_with_md}", "msg", env_module: FakeEnv)
      end)

    if old_runner do
      System.put_env("TEST_AGENT_RUNNER", old_runner)
    else
      System.delete_env("TEST_AGENT_RUNNER")
    end

    refute String.contains?(output_crew, "unknown: crew")
    assert Registry.lookup(ElitaRegistry, "crew") != []

    [{pid, _meta}] = Registry.lookup(ElitaRegistry, "crew")
    state_with_md = Agent.Session.fetch(pid)
    assert state_with_md.self == agent_md

    # Test folder ask WITHOUT agent.md
    folder_no_md = Path.join(base, "team")
    File.mkdir_p!(folder_no_md)

    registrations =
      registrations <> ",team:#{folder_no_md}"

    System.put_env("AGENT_REGISTRATIONS", registrations)
    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    output_team =
      capture_io(fn ->
        El.Commands.Ask.execute("team@#{folder_no_md}", "msg", env_module: FakeEnv)
      end)

    if old_runner do
      System.put_env("TEST_AGENT_RUNNER", old_runner)
    else
      System.delete_env("TEST_AGENT_RUNNER")
    end

    refute String.contains?(output_team, "unknown: team")
    assert Registry.lookup(ElitaRegistry, "team") != []

    [{pid_no_md, _meta}] = Registry.lookup(ElitaRegistry, "team")
    state_no_md = Agent.Session.fetch(pid_no_md)
    assert state_no_md.self == nil

    # Test spawn named session
    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    # spawn ward doctor
    output_spawn1 =
      capture_io(fn ->
        El.Commands.Spawn.execute("ward", "agent1")
      end)

    if old_runner do
      System.put_env("TEST_AGENT_RUNNER", old_runner)
    else
      System.delete_env("TEST_AGENT_RUNNER")
    end

    refute String.contains?(output_spawn1, "error")
    [{pid_ward, _meta}] = Registry.lookup(ElitaRegistry, "ward")
    assert pid_ward != nil

    # spawn p1 doctor and spawn p2 doctor are different sessions
    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    output_spawn2 =
      capture_io(fn ->
        El.Commands.Spawn.execute("p1", "agent1")
      end)

    if old_runner do
      System.put_env("TEST_AGENT_RUNNER", old_runner)
    else
      System.delete_env("TEST_AGENT_RUNNER")
    end

    refute String.contains?(output_spawn2, "error")
    [{pid_p1, _meta}] = Registry.lookup(ElitaRegistry, "p1")

    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    output_spawn3 =
      capture_io(fn ->
        El.Commands.Spawn.execute("p2", "agent1")
      end)

    if old_runner do
      System.put_env("TEST_AGENT_RUNNER", old_runner)
    else
      System.delete_env("TEST_AGENT_RUNNER")
    end

    refute String.contains?(output_spawn3, "error")
    [{pid_p2, _meta}] = Registry.lookup(ElitaRegistry, "p2")
    refute pid_p1 == pid_p2

    # spawn duplicate name errors
    output_dup =
      capture_io(fn ->
        El.Commands.Spawn.execute("ward", "agent1")
      end)

    assert String.contains?(output_dup, "error")

    # spawn for unknown agent errors
    output_unknown =
      capture_io(fn ->
        El.Commands.Spawn.execute("xyz", "missing_agent")
      end)

    assert String.contains?(output_unknown, "error")

    # verify ward is registered and active
    active_ward = Registry.lookup(ElitaRegistry, "ward")
    assert active_ward != []
    assert length(active_ward) == 1

    # Test channel semantics: ward addressed twice lands same session with state
    [{pid_ward_before, _}] = Registry.lookup(ElitaRegistry, "ward")
    Agent.start_link(fn -> [] end, name: :channel_test_log)

    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    capture_io(fn ->
      El.Commands.Ask.execute("ward", "msg1", env_module: FakeEnv)
    end)

    if old_runner do
      System.put_env("TEST_AGENT_RUNNER", old_runner)
    else
      System.delete_env("TEST_AGENT_RUNNER")
    end

    [{pid_ward_after1, _}] = Registry.lookup(ElitaRegistry, "ward")
    assert pid_ward_before == pid_ward_after1

    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    capture_io(fn ->
      El.Commands.Ask.execute("ward", "msg2", env_module: FakeEnv)
    end)

    if old_runner do
      System.put_env("TEST_AGENT_RUNNER", old_runner)
    else
      System.delete_env("TEST_AGENT_RUNNER")
    end

    [{pid_ward_after2, _}] = Registry.lookup(ElitaRegistry, "ward")
    assert pid_ward_before == pid_ward_after2

    # Test ls shows ward active
    output_ls_ward = capture_io(fn -> El.Commands.Ls.execute() end)
    assert String.contains?(output_ls_ward, "ward")
    assert String.contains?(output_ls_ward, "active")
  end

  test "tell-based ask receives reply directly instead of timeout" do
    ref = make_ref()
    caller = self()

    spawn_link(fn ->
      Process.sleep(10)
      send(caller, {ref, "prompt response"})
    end)

    start_time = System.monotonic_time(:millisecond)

    received =
      receive do
        {^ref, answer} -> answer
      after
        5000 -> :timeout
      end

    elapsed = System.monotonic_time(:millisecond) - start_time

    assert received == "prompt response"
    assert elapsed < 500, "reply should arrive promptly, got #{elapsed}ms"
  end
end

defmodule ToolPrefixTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "tool prefix selects harness session (claude vs codex)" do
    base =
      System.tmp_dir()
      |> Path.join("elita_tool_test_#{System.unique_integer()}")

    File.mkdir_p!(base)
    base = Path.expand(base)

    folder = Path.expand(Path.join(base, "agent1"))
    File.mkdir_p!(folder)

    old_cwd = File.cwd!()
    File.cd!(base)

    registrations = "agent1:#{folder}"
    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", registrations)

    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    via_base =
      {:via, Registry, {ElitaRegistry, "agent1", %{kind: :native, folder: folder}}}

    GenServer.start_link(StubAgent, "agent1", name: via_base)

    on_exit(fn ->
      File.cd!(old_cwd)
      System.put_env("AGENT_REGISTRATIONS", old_registrations || "")
      File.rm_rf!(base)
    end)

    System.put_env("TEST_AGENT_RUNNER", "StubRunner")

    # Test 1: bare ask should work (no tool prefix)
    output1 =
      capture_io(fn ->
        El.Commands.Ask.execute("agent1", "msg", nil, env_module: FakeEnv)
      end)

    refute String.contains?(output1, "unknown: agent1")

    # Test 2: claude tool prefix (falls back to bare if tool session not found)
    output2 =
      capture_io(fn ->
        El.Commands.Ask.execute("agent1", "msg", "claude", env_module: FakeEnv)
      end)

    refute String.contains?(output2, "unknown: agent1")

    # Test 3: codex tool prefix (falls back to bare if tool session not found)
    output3 =
      capture_io(fn ->
        El.Commands.Ask.execute("agent1", "msg", "codex", env_module: FakeEnv)
      end)

    refute String.contains?(output3, "unknown: agent1")

    # Test 4: verify claude and codex sessions can coexist for same agent
    via_claude =
      {:via, Registry, {ElitaRegistry, "agent1:claude", %{kind: :native, folder: folder}}}

    GenServer.start_link(StubAgent, "agent1:claude", name: via_claude)

    via_codex =
      {:via, Registry, {ElitaRegistry, "agent1:codex", %{kind: :native, folder: folder}}}

    GenServer.start_link(StubAgent, "agent1:codex", name: via_codex)

    assert Registry.lookup(ElitaRegistry, "agent1:claude") != []
    assert Registry.lookup(ElitaRegistry, "agent1:codex") != []

    assert Registry.lookup(ElitaRegistry, "agent1:claude") !=
             Registry.lookup(ElitaRegistry, "agent1:codex")
  end

  test "unknown tool prefix produces instant error" do
    output =
      capture_io(fn ->
        El.CLI.main(["badtool", "ask", "agent1", "msg"])
      end)

    assert String.contains?(output, "unknown tool: badtool")
  end
end

defmodule FakeEnv do
  def get(_), do: "fake_node@fake_host"
end

defmodule LsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "ls with path forms (bare, relative, absolute, glob)" do
    base =
      System.tmp_dir() |> Path.join("elita_ls_test_#{System.unique_integer()}")

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

    via1 =
      {:via, Registry, {ElitaRegistry, "root_agent", %{kind: :file, path: base}}}

    GenServer.start_link(StubAgent, "root_agent", name: via1)

    via2 =
      {:via, Registry, {ElitaRegistry, "sub_agent", %{kind: :file, path: sub}}}

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

  test "ls // shows connected nodes" do
    base =
      System.tmp_dir()
      |> Path.join("elita_nodes_test_#{System.unique_integer()}")

    File.mkdir_p!(base)
    base = Path.expand(base)

    old_cwd = File.cwd!()
    File.cd!(base)

    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", "")

    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    on_exit(fn ->
      File.cd!(old_cwd)
      System.put_env("AGENT_REGISTRATIONS", old_registrations || "")
      File.rm_rf!(base)
    end)

    output =
      capture_io(fn ->
        El.Commands.Ls.execute(path: "//")
      end)

    node_self = Node.self() |> Atom.to_string()
    assert String.contains?(output, node_self)
    assert String.contains?(output, "node")
  end

  test "world with injected nodes shows entries" do
    nodes_list = [:node1@host, :node2@host]
    world = El.Commands.Address.World.build(fn -> nodes_list end)

    node_kinds =
      world
      |> Enum.filter(&(&1.kind == :node))
      |> Enum.map(& &1.name)

    assert "node1@host" in node_kinds
    assert "node2@host" in node_kinds
  end
end

defmodule PeersTest do
  use ExUnit.Case, async: false

  test "peers round-trip: record and load" do
    tmp =
      System.tmp_dir()
      |> Path.join("elita_peers_test_#{System.unique_integer()}")

    File.mkdir_p!(tmp)

    old_home = System.get_env("HOME")
    System.put_env("HOME", tmp)

    on_exit(fn ->
      if old_home do
        System.put_env("HOME", old_home)
      else
        System.delete_env("HOME")
      end

      File.rm_rf!(tmp)
    end)

    peer1 = :node1@host1
    peer2 = :node2@host2

    El.Peers.record(peer1)
    El.Peers.record(peer2)

    loaded = El.Peers.load()

    assert peer1 in loaded
    assert peer2 in loaded
    assert Enum.all?(loaded, &is_atom/1)
  end

  test "distribution redial connects to loaded peers" do
    peers = [:mock1@host, :mock2@host]
    _connected = []

    fake_connect = fn peer ->
      Agent.update(:mock_connects, &[peer | &1])
    end

    Agent.start_link(fn -> [] end, name: :mock_connects)

    redial(peers, fake_connect)

    calls = Agent.get(:mock_connects, & &1)

    assert :mock1@host in calls
    assert :mock2@host in calls
  end

  defp redial(peers, connect_fn) do
    peers |> Enum.each(connect_fn)
  rescue
    _ -> :ok
  end
end

defmodule RelayTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "peer node relays via rpc function" do
    base =
      System.tmp_dir()
      |> Path.join("elita_relay_test_#{System.unique_integer()}")

    File.mkdir_p!(base)
    base = Path.expand(base)

    old_cwd = File.cwd!()
    File.cd!(base)

    registrations = ""
    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", registrations)

    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    on_exit(fn ->
      File.cd!(old_cwd)
      System.put_env("AGENT_REGISTRATIONS", old_registrations || "")
      File.rm_rf!(base)
    end)

    Agent.start_link(fn -> [] end, name: :relay_log)

    fake_rpc = fn node, module, func, args ->
      Agent.update(:relay_log, &[{node, module, func, args} | &1])
      :ok
    end

    nodes = [:peer1@host]
    world = El.Commands.Address.World.build(fn -> nodes end)

    capture_io(fn ->
      El.Commands.Address.route("peer1@host", "test msg", :ask, nil,
        rpc: fake_rpc,
        world: world
      )
    end)

    calls = Agent.get(:relay_log, & &1)
    assert calls != []

    [{captured_node, captured_module, captured_func, _captured_args}] = calls
    assert captured_node == :peer1@host
    assert captured_module == El.Commands.Address
    assert captured_func == :route
  end

  test "local entry does not touch rpc function" do
    base =
      System.tmp_dir()
      |> Path.join("elita_local_test_#{System.unique_integer()}")

    File.mkdir_p!(base)
    base = Path.expand(base)

    folder = Path.expand(Path.join(base, "agent1"))
    File.mkdir_p!(folder)

    old_cwd = File.cwd!()
    File.cd!(base)

    registrations = "agent1:#{folder}"
    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", registrations)

    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    via1 =
      {:via, Registry, {ElitaRegistry, "agent1", %{kind: :native, folder: folder}}}

    GenServer.start_link(StubAgent, "agent1", name: via1)

    on_exit(fn ->
      File.cd!(old_cwd)
      System.put_env("AGENT_REGISTRATIONS", old_registrations || "")
      File.rm_rf!(base)
    end)

    Agent.start_link(fn -> [] end, name: :relay_log)

    fake_rpc = fn node, module, func, args ->
      Agent.update(:relay_log, &[{node, module, func, args} | &1])
      :ok
    end

    world = El.Commands.Address.World.build(fn -> [] end)

    capture_io(fn ->
      El.Commands.Address.route("agent1", "test msg", :ask, nil,
        rpc: fake_rpc,
        world: world
      )
    end)

    calls = Agent.get(:relay_log, & &1)
    assert calls == []
  end

  test "tell mode relays via rpc function" do
    base =
      System.tmp_dir()
      |> Path.join("elita_tell_relay_test_#{System.unique_integer()}")

    File.mkdir_p!(base)
    base = Path.expand(base)

    old_cwd = File.cwd!()
    File.cd!(base)

    registrations = ""
    old_registrations = System.get_env("AGENT_REGISTRATIONS")
    System.put_env("AGENT_REGISTRATIONS", registrations)

    Registry.start_link(keys: :duplicate, name: ElitaRegistry)

    on_exit(fn ->
      File.cd!(old_cwd)
      System.put_env("AGENT_REGISTRATIONS", old_registrations || "")
      File.rm_rf!(base)
    end)

    Agent.start_link(fn -> [] end, name: :relay_log)

    fake_rpc = fn node, module, func, args ->
      Agent.update(:relay_log, &[{node, module, func, args} | &1])
      :ok
    end

    nodes = [:peer1@host]
    world = El.Commands.Address.World.build(fn -> nodes end)

    capture_io(fn ->
      El.Commands.Address.route("peer1@host", "test msg", :tell, nil,
        rpc: fake_rpc,
        world: world
      )
    end)

    calls = Agent.get(:relay_log, & &1)
    assert calls != []

    [{_captured_node, _captured_module, _captured_func, captured_args}] = calls
    refute Enum.empty?(captured_args)
  end
end

defmodule StubAgent do
  use GenServer

  def init(state), do: {:ok, state}

  def handle_call({:act, _msg}, _from, state) do
    {:reply, "stub response", state}
  end
end

defmodule AddressTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  test "ask with address forms (bare, relative, absolute, unknown, ambiguous)" do
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
    Registry.start_link(keys: :unique, name: ElitaRegistry)

    via1 = {:via, Registry, {ElitaRegistry, "agent1", %{kind: :native, folder: bare_folder}}}
    GenServer.start_link(StubAgent, "ok", name: via1)

    via2 = {:via, Registry, {ElitaRegistry, "agent2", %{kind: :native, folder: deep_folder}}}
    GenServer.start_link(StubAgent, "ok", name: via2)

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
  end
end



defmodule PtyTest do
  use ExUnit.Case

  setup do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    Application.put_env(:el, :call_agent, agent)

    on_exit(fn ->
      Application.delete_env(:el, :call_agent)
    end)

    {:ok, agent: agent}
  end

  defmodule Call do
    def track(label, data \\ nil) do
      agent = Application.get_env(:el, :call_agent)

      if agent do
        Agent.update(agent, &[{label, data} | &1])
      end
    end
  end

  defmodule FakeFile do
    def open(path, opts) do
      Call.track(:file_open, {path, opts})
      {:ok, {:fake_file, path}}
    end

    def write(handle, data) do
      Call.track(:file_write, {handle, data})
      :ok
    end

    def close(handle) do
      Call.track(:file_close, handle)
      :ok
    end

    def read(:user, _bytes) do
      {:error, :eio}
    end

    def read({:fake_file, "/dev/tty"}, _bytes) do
      :eof
    end

    def read(_handle, _bytes) do
      {:ok, ""}
    end
  end

  defmodule FakePort do
    def open(spec, opts) do
      Call.track(:port_open, {spec, opts})
      :fake_port
    end

    def command(port, data) do
      Call.track(:port_command, {port, data})
      :ok
    end

    def info(port, :os_pid) do
      Call.track(:port_info, {port, :os_pid})
      {:os_pid, 12345}
    end

    def info(port) do
      Call.track(:port_info, port)
      [{:os_pid, 12345}]
    end
  end

  defp get_calls(agent) do
    Agent.get(agent, & &1)
  end

  defp clear_calls(agent) do
    Agent.update(agent, fn _ -> [] end)
  end

  test "init opens port with script wrapper", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:port_open, {{:spawn_executable, "/usr/bin/script"}, opts}} ->
        Enum.any?(opts, fn
          {:args, ["-q", "/dev/null", "sh", "-c", _]} -> true
          _ -> false
        end)
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "init applies terminal size via stty", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort,
      get_size: fn -> {42, 100} end
    )

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:port_open, {{:spawn_executable, "/usr/bin/script"}, opts}} ->
        Enum.any?(opts, fn
          {:args, ["-q", "/dev/null", "sh", "-c", cmd]} ->
            String.contains?(cmd, "stty rows 42 cols 100") and String.contains?(cmd, "exec mycmd")
          _ -> false
        end)
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "init opens tty for write", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:file_open, {"/dev/tty", [:write, :binary, :raw]}} -> true
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "init spawns read loop that opens tty for read", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)

    calls = get_calls(agent)
    write_opens = Enum.filter(calls, fn
      {:file_open, {"/dev/tty", [:write, :binary, :raw]}} -> true
      _ -> false
    end)
    read_opens = Enum.filter(calls, fn
      {:file_open, {"/dev/tty", [:read, :binary, :raw]}} -> true
      _ -> false
    end)

    assert length(write_opens) > 0
    assert length(read_opens) > 0

    GenServer.stop(pid)
  end

  test "port data message writes to tty", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)
    clear_calls(agent)

    send(pid, {:fake_port, {:data, "hello"}})

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:file_write, {{:fake_file, "/dev/tty"}, "hello"}} -> true
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "stdin message sends to port", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)
    clear_calls(agent)

    send(pid, {:stdin, "data"})

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:port_command, {:fake_port, "data"}} -> true
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "inject sends to port", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)
    clear_calls(agent)

    El.Pty.inject(:test_pty, "injected")

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:port_command, {:fake_port, "injected"}} -> true
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "exit_status stops normally and closes tty", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)

    ref = Process.monitor(pid)

    send(pid, {:fake_port, {:exit_status, 0}})

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:file_close, {:fake_file, "/dev/tty"}} -> true
      _ -> false
    end)

    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 1000
  end

  test "exit_status captures and kills process group", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)

    ref = Process.monitor(pid)

    send(pid, {:fake_port, {:exit_status, 0}})

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:port_info, {:fake_port, :os_pid}} -> true
      _ -> false
    end)

    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 1000
  end

  test "input hook transforms stdin bytes before port.command", %{agent: agent} do
    upcase = fn bytes -> String.upcase(bytes) end

    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort,
      input: upcase
    )

    Process.sleep(50)
    clear_calls(agent)

    send(pid, {:stdin, "hello"})

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:port_command, {:fake_port, "HELLO"}} -> true
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "input :drop suppresses stdin bytes", %{agent: agent} do
    drop_all = fn _bytes -> :drop end

    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort,
      input: drop_all
    )

    Process.sleep(50)
    clear_calls(agent)

    send(pid, {:stdin, "data"})

    Process.sleep(50)

    calls = get_calls(agent)
    assert !Enum.any?(calls, fn
      {:port_command, {:fake_port, _}} -> true
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "default input is identity", %{agent: agent} do
    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)
    clear_calls(agent)

    send(pid, {:stdin, "untouched"})

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:port_command, {:fake_port, "untouched"}} -> true
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "taps receive output chunks", %{agent: _agent} do
    caller = self()

    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort,
      taps: [caller]
    )

    Process.sleep(50)

    send(pid, {:fake_port, {:data, "output"}})

    Process.sleep(50)

    assert_receive {:output, "output"}, 1000

    GenServer.stop(pid)
  end

  test "inject bypasses input hook", %{agent: agent} do
    upcase = fn bytes -> String.upcase(bytes) end

    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort,
      input: upcase
    )

    Process.sleep(50)
    clear_calls(agent)

    El.Pty.inject(:test_pty, "injected")

    Process.sleep(50)

    calls = get_calls(agent)
    assert Enum.any?(calls, fn
      {:port_command, {:fake_port, "injected"}} -> true
      _ -> false
    end)

    GenServer.stop(pid)
  end

  test "dsr responses unaffected by taps", %{agent: agent} do
    caller = self()

    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort,
      taps: [caller]
    )

    Process.sleep(50)
    clear_calls(agent)

    send(pid, {:fake_port, {:data, "\e[6n"}})

    Process.sleep(50)

    calls = get_calls(agent)
    dsr_responses = Enum.filter(calls, fn
      {:port_command, {:fake_port, _}} -> true
      _ -> false
    end)

    assert length(dsr_responses) > 0

    GenServer.stop(pid)
  end


  test "traces stdin data when EL_TRACE set" do
    trace_file = Path.join(System.tmp_dir!(), "pty_trace_#{System.unique_integer()}.log")
    System.put_env("EL_TRACE", trace_file)

    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)

    send(pid, {:stdin, "traced"})

    Process.sleep(50)

    assert File.exists?(trace_file)
    content = File.read!(trace_file)
    assert String.contains?(content, "traced")

    GenServer.stop(pid)
    System.delete_env("EL_TRACE")
    File.rm(trace_file)
  end

  test "traces inject data when EL_TRACE set" do
    trace_file = Path.join(System.tmp_dir!(), "pty_inject_trace_#{System.unique_integer()}.log")
    System.put_env("EL_TRACE", trace_file)

    {:ok, pid} = El.Pty.start_link(
      :test_pty,
      "mycmd",
      file: FakeFile,
      port: FakePort
    )

    Process.sleep(50)

    El.Pty.inject(:test_pty, "injected")

    Process.sleep(50)

    assert File.exists?(trace_file)
    content = File.read!(trace_file)
    assert String.contains?(content, "injected")

    GenServer.stop(pid)
    System.delete_env("EL_TRACE")
    File.rm(trace_file)
  end

end

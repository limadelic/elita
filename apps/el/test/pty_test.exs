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
      {:port_open, {{:spawn, cmd}, _}} -> String.contains?(cmd, "script -q /dev/null mycmd")
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
end

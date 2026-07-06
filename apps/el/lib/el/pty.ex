defmodule El.Pty do
  use GenServer

  def start_link(name, cmd, opts \\ []) do
    GenServer.start_link(__MODULE__, {cmd, opts}, name: name)
  end

  def inject(name, message) do
    GenServer.cast(name, {:inject, message})
  end

  def run(name, opts \\ []) do
    {:ok, pid} = start_link(name, "claude --dangerously-skip-permissions", opts)
    wait_for_exit(pid)
  end

  defp wait_for_exit(pid) do
    ref = Process.monitor(pid)
    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    end
  end

  @impl true
  def init({cmd, opts}) do
    file = Keyword.get(opts, :file, :file)
    port = Keyword.get(opts, :port, Port)
    {:ok, setup(file, port, cmd)}
  end

  defp setup(file, port, cmd) do
    pty = open_pty(port, cmd)
    {:ok, tty_out} = file.open("/dev/tty", [:write, :binary, :raw])
    Process.flag(:trap_exit, true)
    spawn_link(fn -> read_loop(file, self()) end)
    %{pty: pty, file: file, port: port, tty_out: tty_out}
  end

  defp open_pty(port, cmd) do
    wrapped_cmd = "script -q /dev/null " <> cmd
    port.open({:spawn, wrapped_cmd}, [:binary, :stream, :exit_status])
  end

  @impl true
  def handle_info({pty, {:data, data}}, %{pty: pty, file: file, tty_out: tty_out} = state) do
    file.write(tty_out, data)
    {:noreply, state}
  end

  def handle_info({pty, {:exit_status, _}}, %{pty: pty, file: file, tty_out: tty_out} = state) do
    file.close(tty_out)
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info({:stdin, data}, %{pty: pty, port: port} = state) do
    port.command(pty, data)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:inject, msg}, %{pty: pty, port: port} = state) do
    port.command(pty, msg)
    {:noreply, state}
  end

  defp read_loop(file, parent) do
    case file.open("/dev/stdin", [:read, :binary, :raw]) do
      {:ok, stdin} -> read_until_eof(file, stdin, parent)
      {:error, _} -> :ok
    end
  end

  defp read_until_eof(file, tty_in, parent) do
    read_until_eof(file, tty_in, parent, file.read(tty_in, 1))
  end

  defp read_until_eof(file, tty_in, parent, {:ok, data}) do
    send(parent, {:stdin, data})
    read_until_eof(file, tty_in, parent)
  end

  defp read_until_eof(file, tty_in, _parent, _) do
    file.close(tty_in)
  end
end

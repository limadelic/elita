defmodule El.Pty do
  use GenServer
  import El.PtyReader, only: [start: 2]

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
    get_size = Keyword.get(opts, :get_size, &default_get_size/0)
    {:ok, setup(file, port, cmd, get_size)}
  end

  defp setup(file, port, cmd, get_size) do
    parent = self()
    pty = open_pty(port, cmd, get_size)
    {:ok, tty_out} = file.open("/dev/tty", [:write, :binary, :raw])
    Process.flag(:trap_exit, true)
    spawn_link(fn -> start(file, parent) end)
    %{pty: pty, file: file, port: port, tty_out: tty_out}
  end

  defp open_pty(port, cmd, get_size) do
    {rows, cols} = get_size.()
    stty_cmd = "stty rows #{rows} cols #{cols};"
    wrapped_cmd = "script -q /dev/null sh -c '#{stty_cmd} exec #{cmd}'"
    port.open({:spawn, wrapped_cmd}, [:binary, :stream, :exit_status])
  end

  defp default_get_size do
    System.cmd("sh", ["-c", "stty size < /dev/tty"], stderr_to_stdout: true)
    |> parse_size()
  rescue
    _ -> {24, 80}
  end

  defp parse_size({output, 0}) do
    String.trim(output)
    |> String.split()
    |> extract_size()
  end

  defp parse_size(_), do: {24, 80}

  defp extract_size([rows, cols]), do: {String.to_integer(rows), String.to_integer(cols)}
  defp extract_size(_), do: {24, 80}

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
end

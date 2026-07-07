defmodule El.Pty.Init do
  @moduledoc false
  import El.PtyReader
  import El.Trace

  def call(cfg) do
    size = cfg[:get_size].()
    {pty, os_pid, tty_out} = init_pty(cfg, size)
    post_init(cfg, pty, size, tty_out, os_pid)
  end

  defp init_pty(cfg, size) do
    {pty, os_pid} = pty_and_pid(cfg[:port], cfg[:cmd], size)
    {:ok, tty_out} = cfg[:file].open("/dev/tty", [:write, :binary, :raw])
    {pty, os_pid, tty_out}
  end

  defp post_init(cfg, pty, size, tty_out, os_pid) do
    setup(cfg[:file], pty, size)
    monitor_port(pty)
    make_state(pty, cfg, tty_out, os_pid)
  end

  defp make_state(pty, cfg, tty_out, os_pid) do
    %{
      pty: pty,
      file: cfg[:file],
      port: cfg[:port],
      tty_out: tty_out,
      os_pid: os_pid,
      input: cfg[:input],
      taps: cfg[:taps]
    }
  end

  defp pty_and_pid(port, cmd, size) do
    pty = open_pty(port, cmd, size)
    {pty, extract_pid(port.info(pty, :os_pid))}
  end

  defp extract_pid({:os_pid, pid}), do: pid
  defp extract_pid(_), do: nil

  defp open_pty(port, cmd, size) do
    {rows, cols} = size
    stty = "stty rows #{rows} cols #{cols}; stty raw -echo -isig;"
    args = ["-q", "/dev/null", "sh", "-c", "#{stty} exec #{cmd}"]

    port.open(
      {:spawn_executable, "/usr/bin/script"},
      [:binary, :stream, :exit_status, {:args, args}]
    )
  end

  defp setup(file, _pty, size) do
    {:ok, fd} = file.open("/dev/tty", [:read, :binary, :raw])
    log_header(size, tty_or_user(fd, file))
    Process.flag(:trap_exit, true)
    spawn_link(fn -> start(file, self()) end)
  end

  defp tty_or_user(fd, file) do
    file.close(fd)
    :tty
  rescue
    _ -> :user
  end

  defp monitor_port(pty) do
    parent = self()

    Process.spawn(
      fn ->
        Process.sleep(500)
        check_port(parent, pty)
      end,
      []
    )
  end

  defp check_port(parent, pty) do
    handle_port(Port.info(pty), parent, pty)
  end

  defp handle_port(false, parent, pty), do: send(parent, {pty, :closed})
  defp handle_port(_, _, _), do: :ok
end

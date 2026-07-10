defmodule El.Pty.Init do
  @moduledoc false
  import El.Reader
  import El.Trace
  import Map
  import Process, except: [alias: 1, info: 1]
  import Port, only: [info: 1]

  def call(cfg) do
    size = cfg[:get_size].()
    {pty, child, out} = boot(cfg, size)
    finish(cfg, pty, size, out, child)
  end

  defp boot(cfg, size) do
    {pty, child} = pair(cfg[:port], cfg[:cmd], size)
    {:ok, out} = cfg[:file].open("/dev/stdout", [:write, :binary])
    {pty, child, out}
  end

  defp finish(cfg, pty, size, out, child) do
    setup(cfg[:file], pty, size)
    watch(pty)
    core(pty, out, child) |> attach(cfg)
  end

  defp core(pty, out, child) do
    %{pty: pty, out: out, child: child}
  end

  defp attach(state, cfg) do
    merge(state, extras(cfg))
  end

  defp extras(cfg) do
    %{file: cfg[:file], port: cfg[:port], input: cfg[:input], taps: cfg[:taps]}
  end

  defp pair(port, cmd, size) do
    pty = launch(port, cmd, size)
    child = port.info(pty, :os_pid)
    {pty, pid(child)}
  end

  defp pid({:os_pid, pid_val}), do: pid_val
  defp pid(_), do: nil

  defp launch(port, cmd, size) do
    argv = args(size, cmd)
    opts = [:binary, :stream, :exit_status, {:args, argv}]
    port.open({:spawn_executable, "/usr/bin/script"}, opts)
  end

  defp args({rows, cols}, cmd) do
    stty = "stty rows #{rows} cols #{cols}; stty raw -echo -isig;"
    ["-q", "/dev/null", "sh", "-c", "#{stty} exec #{cmd}"]
  end

  defp setup(file, _pty, size) do
    {:ok, fd} = file.open("/dev/tty", [:read, :binary, :raw])
    mark(size, sink(fd, file))
    pump(file)
  end

  defp pump(file) do
    flag(:trap_exit, true)
    parent = self()
    spawn_link(fn -> start(file, parent) end)
  end

  defp sink(fd, file) do
    file.close(fd)
    :tty
  rescue
    _ -> :user
  end

  defp watch(pty) do
    spawn(fn -> probe(self(), pty) end, [])
  end

  defp probe(parent, pty) do
    sleep(500)
    test(parent, pty)
  end

  defp test(parent, pty) do
    react(info(pty), parent, pty)
  end

  defp react(nil, parent, pty), do: send(parent, {pty, :closed})
  defp react(_, _, _), do: :ok
end

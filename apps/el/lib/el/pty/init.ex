defmodule El.Pty.Init do
  @moduledoc false
  import El.Reader
  import El.Trace
  import Map
  import Process, except: [alias: 1, info: 1]
  import Port, only: [info: 1]

  def call(cfg) do
    import El.Log, only: [write: 1]
    size = cfg[:get_size].()
    write("pty boot: size=#{inspect(size)}\n")
    {pty, os_pid, out} = boot(cfg, size)
    write("pty boot done: pty=#{inspect(pty)} os_pid=#{os_pid}\n")
    finish(cfg, pty, size, out, os_pid)
  rescue
    e ->
      import El.Log, only: [write: 1]
      write("pty boot error: #{inspect(e)}\n")
      reraise e, __STACKTRACE__
  end

  defp boot(cfg, size) do
    import El.Log, only: [write: 1]
    {pty, os_pid} = pair(cfg[:port], cfg[:cmd], size)
    write("pty pair done: pty=#{inspect(pty)}\n")
    {:ok, out} = cfg[:file].open("/dev/stdout", [:write, :binary])
    {pty, os_pid, out}
  rescue
    e ->
      import El.Log, only: [write: 1]
      write("pty boot detailed error: #{inspect(e)}\n")
      reraise e, __STACKTRACE__
  end

  defp finish(cfg, pty, size, out, os_pid) do
    import El.Log, only: [write: 1]
    write("pty init: my PID is #{inspect(self())}\n")
    setup(cfg[:file], pty, size)
    watch(pty)
    core(pty, out, os_pid) |> attach(cfg)
  end

  defp core(pty, out, os_pid) do
    %{pty: pty, out: out, os_pid: os_pid}
  end

  defp attach(state, cfg) do
    merge(state, extras(cfg))
  end

  defp extras(cfg) do
    %{file: cfg[:file], port: cfg[:port], input: cfg[:input], taps: cfg[:taps]}
  end

  defp pair(port, cmd, size) do
    pty = launch(port, cmd, size)
    os_pid = port.info(pty, :os_pid)
    {pty, pid(os_pid)}
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
    import El.Log, only: [write: 1]
    {:ok, fd} = file.open("/dev/tty", [:read, :binary, :raw])
    mark(size, sink(fd, file))
    flag(:trap_exit, true)
    my_pid = self()
    write("setup: my PID before spawn_link is #{inspect(my_pid)}\n")
    spawn_link(fn ->
      write("setup: inside spawn_link fn, about to call start with parent=#{inspect(my_pid)}\n")
      start(file, my_pid)
    end)
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

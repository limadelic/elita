defmodule El.Pty.Init do
  @moduledoc false
  import El.Reader
  import El.Trace
  import El.Pty.Env
  import Map
  import Process, except: [alias: 1, info: 1]
  import Port, only: [info: 1]
  def call(cfg) do
    size = cfg[:get_size].()
    {pty, child, out, raw} = boot(cfg, size)
    finish(cfg, pty, size, {out, raw, child})
  end
  defp boot(cfg, size) do
    {pty, child} = pair(cfg[:port], cfg[:cmd], size)
    {pty, child, :stdio, snap()}
  end
  defp snap do
    n = Process.info(self(), :registered_name) |> elem(1)
    p = "#{System.get_env("HOME", "~")}/.elita/sessions/#{n}.raw"
    safely(fn -> p |> to_charlist() |> :file.open([:write, :binary]) |> elem(1) end, nil)
  end

  defp safely(fun, default) do
    fun.()
  rescue
    _ -> default
  end
  defp finish(cfg, pty, size, {out, raw, child}) do
    setup(cfg[:file], pty, size)
    watch(pty)
    core(pty, out, raw, child) |> attach(cfg)
  end
  defp core(pty, out, raw, child) do
    %{pty: pty, out: out, raw: raw, child: child,
      ready: false, buffer: [], tail: "",
      pending_msg: nil, idle: false, idle_count: 0}
  end
  defp attach(state, cfg) do
    merge(state, %{file: cfg[:file], port: cfg[:port],
      input: cfg[:input], taps: cfg[:taps]})
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
    port.open({:spawn_executable, "/usr/bin/script"},
      [:binary, :stream, :exit_status, {:args, argv}, {:env, unset()}])
  end
  defp args({rows, cols}, cmd) do
    stty = "stty rows #{rows} cols #{cols}; stty raw -echo -isig;"
    argv(:os.type(), stty, cmd)
  end

  defp argv({:unix, :darwin}, stty, cmd) do
    ["-q", "/dev/null", "sh", "-c", "#{stty} exec #{cmd}"]
  end

  defp argv({:unix, _}, stty, cmd) do
    ["-q", "-c", "#{stty} exec #{cmd}", "/dev/null"]
  end

  defp setup(file, _pty, size) do
    file.open("/dev/tty", [:read, :binary, :raw])
    |> mirror(file, size)
  end

  defp mirror({:ok, fd}, file, size) do
    mark(size, sink(fd, file))
    pump(file)
  end

  defp mirror({:error, reason}, _, _) when reason in [:enxio, :ebadf, :enotty], do: :ok

  defp pump(file) do
    flag(:trap_exit, true)
    parent = self()
    spawn_link(fn -> start(file, parent) end)
  end

  defp sink(fd, file), do: safely(fn -> file.close(fd); :tty end, :user)

  defp watch(pty) do
    spawn(fn -> probe(self(), pty) end, [])
  end

  defp probe(parent, pty) do
    sleep(500)
    react(info(pty), parent, pty)
  end

  defp react(nil, parent, pty), do: send(parent, {pty, :closed})
  defp react(_, _, _), do: :ok
end

defmodule El.Pty.Init do
  @moduledoc false
  import El.Reader
  import El.Trace
  import El.Pty.State, only: [initial: 4, config: 2]
  import El.Pty.Boot, only: [launch: 3]
  import El.Pty.Watch, only: [start: 1]
  import Process, except: [alias: 1, info: 1]

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
    start(pty)
    initial(pty, out, raw, child) |> config(cfg)
  end

  defp pair(port, cmd, size) do
    pty = launch(port, cmd, size)
    child = port.info(pty, :os_pid)
    {pty, pid(child)}
  end

  defp pid({:os_pid, pid_val}), do: pid_val
  defp pid(_), do: nil

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

  defp sink(fd, file),
    do:
      safely(
        fn ->
          file.close(fd)
          :tty
        end,
        :user
      )
end

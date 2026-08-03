defmodule Matrix.Pty.Init do
  @moduledoc false
  import Matrix.Reader
  import Matrix.Trace
  import Matrix.Pty.State, only: [initial: 4, config: 2]
  import Matrix.Pty.Boot, only: [launch: 3]
  import Matrix.Pty.Watch, only: [start: 1]
  import Process, only: [flag: 2]
  import Matrix.Movie.Record, only: [active?: 0]
  alias Matrix.Movie.Record

  def call(cfg) do
    size = cfg[:get_size].()
    {pty, child, out, raw} = boot(cfg, size)
    finish(cfg, pty, size, {out, raw, child})
  end

  defp boot(cfg, size) do
    {pty, child} = pair(cfg[:port], cfg[:cmd], size)
    {pty, child, :stdio, nil}
  end

  defp finish(cfg, pty, size, {out, raw, child}) do
    setup(cfg[:file], pty, size)
    start(pty)
    state = initial(pty, out, raw, child) |> config(cfg)
    rec(state, pty, cfg[:name])
  end

  defp rec(state, pty, name) do
    recorder =
      case {active?(), is_pid(pty)} do
        {true, true} -> Record.start(pty, name)
        _ -> nil
      end

    %{state | recorder: recorder}
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

  defp sink(fd, file) do
    file.close(fd)
    :tty
  rescue
    _ -> :user
  end
end

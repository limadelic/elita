defmodule El.Commands.Claude do
  @moduledoc false
  import :os, only: [cmd: 1]
  import Matrix.Pty, only: [launch: 2]
  import String, only: [to_atom: 1, replace: 3]
  import System, only: [get_env: 2, find_executable: 1]
  import El.Commands.Size, only: [size: 0]
  import El.Commands.Reset, only: [cleanup: 0]
  import File, only: [cwd!: 0]
  import Path, only: [basename: 1]
  import Matrix.Wrap.Resize, only: [watch: 2]
  import Matrix.Wrap.Input, only: [open: 2, encode: 2]
  import Matrix.Log, only: [write: 1]
  import El.Distribution, only: [bind: 1, start: 1, target: 1, wait: 1]
  import El.Puppet, only: [open: 1, ask: 2, put: 2]
  import El.Puppet.Collect, only: [collect: 1]
  import Agent, only: [start: 2]
  import El.Cmd, only: [build: 0]

  def claude(name \\ :default) do
    claude(name, deps())
  end

  defp deps, do: [distribution_start: &start/1, cmd: &cmd/1, launch: &launch/2]

  def claude(name, deps) when is_list(deps) do
    write("boot: #{name}\n")
    go(resolve(name), deps)
  after
    cleanup()
  end

  defp go(name, deps) do
    spawn(fn -> distribute(name, deps) end)
    boot(to_atom(name), deps)
  rescue
    e -> write("boot error during claude setup: #{inspect(e)}\n")
  end

  defp distribute(name, deps) do
    Keyword.get(deps, :distribution_start).(name)
  rescue
    e -> write("distribution error: #{inspect(e)}\n")
  end

  defp boot(name, deps) do
    setup(deps)
    tape()
    buf = open(self(), name)
    execute(name, deps, buf)
  end

  defp setup(deps) do
    Keyword.get(deps, :cmd).(~c"stty raw -echo -isig < /dev/tty")
  rescue
    _ -> :ok
  end

  defp execute(name, deps, buf) do
    cmd = finalize(build())
    pid = Keyword.get(deps, :launch).(name, opts(buf, cmd))
    install(name)
    hold(pid)
  end

  defp hold(pid) when is_pid(pid), do: Matrix.Pty.wait(pid)
  defp hold(_), do: :ok

  defp opts(buf, cmd) do
    input = fn chunk -> encode(buf, chunk) end
    base = [cmd: cmd, get_size: &size/0, input: input, resize: &resize/1]
    base ++ [size: &size/0] ++ invert()
  end

  defp resize(pid), do: watch(pid, size: &size/0)

  defp invert do
    [wait: &wait/1, target: &target/1] ++
      [ask: &ask/2, far: &far/3, put: &put/2, collect: &collect/1]
  end

  defp far(node, pid, msg) do
    :erpc.call(node, El.Puppet, :ask, [pid, msg], 90_000)
  end

  defp install(name) do
    open(name: name, pty: name)
    bind(name)
  end

  defp resolve(:default), do: cwd!() |> basename()
  defp resolve(name) when is_binary(name), do: name
  defp tape, do: mode(get_env("TAPE", nil))
  defp mode("rec"), do: start(fn -> %{} end, name: Tape.Writer)
  defp mode(_), do: :ok
  defp finalize(cmd), do: find_executable("claude") |> done(cmd)
  defp done(nil, cmd), do: cmd
  defp done(path, cmd), do: replace(cmd, ~r/^claude\b/, path)
end

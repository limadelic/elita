defmodule El.Commands.Claude do
  @moduledoc false
  import :os, only: [cmd: 1]
  import El.Pty, only: [launch: 2, wait: 1]
  import El.Distribution, only: [start: 1]
  import String, only: [to_atom: 1]
  import IO, only: [puts: 1]
  import System, only: [halt: 1, get_env: 2]
  import El.Commands.Size, only: [size: 0]
  import File, only: [write!: 2, cwd!: 0]
  import Path, only: [basename: 1]
  import El.Wrap.Resize, only: [watch: 1]
  import El.Wrap.Input, only: [open: 2, encode: 2]
  import El.Log, only: [write: 1]
  import El.Puppet, only: [start_link: 1]
  alias Registry

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

  defp cleanup do
    write("shutdown\n")
    reset()
    stty()
  end

  defp reset do
    write!("/dev/tty", "\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l\e[?1049l\e[?25h")
  rescue
    _ -> :ok
  end

  defp stty do
    cmd(~c"stty sane < /dev/tty")
  rescue
    _ -> :ok
  end

  defp go(name, deps) do
    validate(Keyword.get(deps, :distribution_start).(name), name)
    boot(to_atom(name), deps)
  end

  defp validate(:taken, name) do
    puts("session #{name} already live — el tell #{name} <msg>, or /exit it")
    halt(1)
  end

  defp validate(_, _), do: :ok

  defp boot(process_name, deps) do
    setup(deps)
    buf = open(self(), process_name)
    execute(process_name, deps, buf)
  end

  defp setup(deps) do
    Keyword.get(deps, :cmd).(~c"stty raw -echo -isig < /dev/tty")
  rescue
    _ -> :ok
  end

  defp execute(name, deps, buf) do
    cmd = "claude --dangerously-skip-permissions --model #{get_env("CLAUDE_MODEL", "haiku")}"
    pid = Keyword.get(deps, :launch).(name, opts(buf, cmd))
    install(name)
    hold(pid)
  end

  defp hold(pid) when is_pid(pid), do: wait(pid)
  defp hold(_), do: :ok

  defp opts(buf, cmd) do
    input = fn chunk -> encode(buf, chunk) end
    [cmd: cmd, get_size: &size/0, input: input, resize: &watch/1]
  end

  defp install(name) do
    prepare()
    start_link(name: name, pty_pid: name)
  end

  defp prepare do
    Registry.start_link(keys: :unique, name: ElitaRegistry)
  rescue
    _ -> :ok
  end

  defp resolve(:default), do: cwd!() |> basename()
  defp resolve(name) when is_binary(name), do: name
end

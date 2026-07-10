defmodule El.Commands.Claude do
  @moduledoc false
  import :os, only: [cmd: 1]
  import El.Pty, only: [run: 2]
  import El.Distribution, only: [start: 1]
  import String, only: [to_atom: 1]
  import IO, only: [puts: 1]
  import System, only: [halt: 1, get_env: 2]
  import El.Commands.Size, only: [size: 0]
  import File, only: [write!: 2, cwd!: 0]
  import Path, only: [basename: 1]
  import El.Wrap.Resize, only: [watch: 1]
  import El.Wrap.Input, only: [open: 1, encode: 2]

  def claude(name \\ :default) do
    claude(name, deps())
  end

  defp deps, do: [distribution_start: &start/1, cmd: &cmd/1, run: &run/2]

  def claude(name, deps) when is_list(deps) do
    go(resolve(name), deps)
  after
    restore()
    stty()
  end

  defp stty do
    cmd(~c"stty sane < /dev/tty")
  rescue
    _ -> :ok
  end

  defp go(session_name, deps) do
    ready(deps, session_name)
    boot(to_atom(session_name), deps)
  end

  defp ready(deps, session_name) do
    Keyword.get(deps, :distribution_start).(session_name)
    |> validate(session_name)
  end

  defp validate(:taken, session_name) do
    puts("session #{session_name} already live — el tell #{session_name} <msg>, or /exit it")
    halt(1)
  end

  defp validate(_, _), do: :ok

  defp boot(process_name, deps) do
    setup(deps)
    buf = open(self())
    execute(process_name, deps, buf)
  end

  defp setup(deps) do
    cmd_fn = Keyword.get(deps, :cmd)
    cmd_fn.(~c"stty raw -echo -isig < /dev/tty")
  rescue
    _ -> :ok
  end

  defp execute(name, deps, buf) do
    model = get_env("CLAUDE_MODEL", "haiku")
    cmd = "claude --dangerously-skip-permissions --model #{model}"
    input_fn = fn chunk -> encode(buf, chunk) end
    Keyword.get(deps, :run).(name, cmd: cmd, get_size: &size/0, input: input_fn, resize: &watch/1)
  end

  defp restore do
    sequence()
  rescue
    _ -> :ok
  end

  defp sequence do
    write!("/dev/tty", "\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l\e[?1049l\e[?25h")
  end

  defp resolve(:default), do: cwd!() |> basename()
  defp resolve(name) when is_binary(name), do: name
end

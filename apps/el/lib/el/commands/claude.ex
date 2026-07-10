defmodule El.Commands.Claude do
  @moduledoc false
  import :os, only: [cmd: 1]
  import El.Pty, only: [run: 2]
  import El.Distribution, only: [start: 1]
  import String, only: [to_atom: 1, replace: 3]
  import Keyword, only: [get: 2]
  import IO, only: [puts: 1]
  import System, only: [halt: 1]
  import El.Commands.Size, only: [read_terminal_size: 0]
  import File, only: [write!: 2, cwd!: 0]
  import Path, only: [basename: 1]

  def execute(name \\ :default) do
    execute(name, deps())
  end

  defp deps, do: [distribution_start: &start/1, cmd: &cmd/1, run: &run/2]

  def execute(name, deps) when is_list(deps) do
    run_with_cleanup(session(name), deps)
  after
    restore()
    cmd(~c"stty sane < /dev/tty")
  end

  defp run_with_cleanup(session_name, deps) do
    ensure_available(deps, session_name)
    start_session(to_atom(session_name), deps)
  end

  defp ensure_available(deps, session_name) do
    get(deps, :distribution_start).(session_name)
    |> check_available(session_name)
  end

  defp check_available(:taken, session_name) do
    puts("session #{session_name} already live — el tell #{session_name} <msg>, or /exit it")

    halt(1)
  end

  defp check_available(_, _), do: :ok

  defp start_session(process_name, deps) do
    raw_mode(deps)
    run_session(process_name, deps)
  end

  defp raw_mode(deps) do
    cmd_fn = get(deps, :cmd)
    cmd_fn.(~c"stty raw -echo -isig < /dev/tty")
  end

  defp run_session(name, deps) do
    run_fn = get(deps, :run)
    opts = [get_size: &read_terminal_size/0, input: &translate_newline/1]
    run_fn.(name, opts)
  end

  defp restore do
    sequence()
  rescue
    _ -> :ok
  end

  defp sequence do
    write!("/dev/tty", "\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l\e[?1049l\e[?25h")
  end

  defp translate_newline(chunk) do
    replace(chunk, "\n", "\r")
  end

  defp session(:default) do
    cwd!()
    |> basename()
  end

  defp session(name) when is_binary(name), do: name
end

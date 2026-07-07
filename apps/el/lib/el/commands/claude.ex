defmodule El.Commands.Claude do
  @moduledoc false
  import :os, only: [cmd: 1]
  import El.Pty, only: [run: 2]

  alias El.Commands.Size
  alias El.Distribution

  def execute(name \\ :default) do
    execute(name,
      distribution_start: &Distribution.start/1,
      cmd: &cmd/1,
      run: &run/2
    )
  end

  def execute(name, deps) when is_list(deps) do
    run_with_cleanup(resolve_session_name(name), deps)
  after
    restore()
    cmd(~c"stty sane < /dev/tty")
  end

  defp run_with_cleanup(session_name, deps) do
    ensure_available(deps, session_name)
    start_session(String.to_atom(session_name), deps)
  end

  defp ensure_available(deps, session_name) do
    Keyword.get(deps, :distribution_start).(session_name)
    |> check_available(session_name)
  end

  defp check_available(:taken, session_name) do
    IO.puts("session #{session_name} already live — el tell #{session_name} <msg>, or /exit it")

    System.halt(1)
  end

  defp check_available(_, _), do: :ok

  defp start_session(process_name, deps) do
    raw_mode(deps)
    run_session(process_name, deps)
  end

  defp raw_mode(deps) do
    cmd_fn = Keyword.get(deps, :cmd)
    cmd_fn.(~c"stty raw -echo -isig < /dev/tty")
  end

  defp run_session(name, deps) do
    run_fn = Keyword.get(deps, :run)
    opts = [get_size: &Size.read_terminal_size/0, input: &translate_newline/1]
    run_fn.(name, opts)
  end

  defp restore do
    write_sequence()
  rescue
    _ -> :ok
  end

  defp write_sequence do
    File.write!("/dev/tty", "\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l\e[?1049l\e[?25h")
  end

  defp translate_newline(chunk) do
    String.replace(chunk, "\n", "\r")
  end

  defp resolve_session_name(:default), do: File.cwd!() |> Path.basename()
  defp resolve_session_name(name) when is_binary(name), do: name
end
